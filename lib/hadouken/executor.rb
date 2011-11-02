class Hadouken::Executor


  class Phase
    attr_accessor :strategy
    attr_accessor :tasks
    def initialize
      @tasks = []
    end
  end

  attr_reader :plan

  def self.run!(plan)
    exec = Hadouken::Executor.new(plan)
    exec.phases
    exec.session!
    exec.execute!
  end


  def initialize(plan)
    @plan    = plan
    @session = Net::SSH::Multi.start

    ## TODO: find a better place for this
    unless @plan.tasks.first.is_a?(Hadouken::Strategy::Base)
      raise RuntimeError, "first task in plan is not a strategy"
    end
  end


  def phases
    return @phases if @phases
    @phases = []
    plan.tasks.each do |task|
      if task.is_a?(Hadouken::Strategy::Base)
        @phases << Phase.new
        @phases.last.strategy = task
      end
 
      if task.is_a?(Hadouken::Task)
        @phases.last.tasks << task
      end
    end

    @phases
  end 

  def session
    @session ||= session!
  end

  def session!
    @session    = Net::SSH::Multi.start
    @server_map = {}

    plan.groups.each do |group|
      group.hosts.each do |host|
        puts "session.use #{host}"
        server = session.use host
        @server_map[host] = server
      end
    end

    @session
  end

  def execute!
    # the heavy lifting: pivot our structure 
    #   from tasks : task : hosts[]
    #   to   hosts : host : tasks[]
    phases.each_with_index do |phase, phase_index|
      strategy         = phase.strategy
      hosts_with_tasks = {}
      host_sets        = strategy.host_strategy

      puts "// #{phase_index} : #{strategy}"

      ## assign work
      host_sets.each do |host_set|
        puts "!! #{host_set.join(', ')}"
      
        host_set.each do |host|
          hosts_with_tasks[host] ||= []

          phase.tasks.each_with_index do |task, izx|
            # if this is not a group task then assign it to the host OR if
            # this is a group task and the host is part of the task-group,
            # then assign the task to the host
            if !task.group_task? || (task.group_task? && task.group.has_host?(host))
              hosts_with_tasks[host] <<  task
            end
          end
        end
      end

      case strategy.traversal
        when :breadth : execute_breadth_traversal! host_sets, hosts_with_tasks
        when :depth   : execute_depth_traversal!   host_sets, hosts_with_tasks
        else raise RuntimeError, "unknown tranversal=#{strategy.traversal}"
      end
    end
  end

  # our next trick is, we need to make it possible for a strategy to run in one
  # of two ways: breadth or depth
  # depth   - run every command assigned to a batch of hosts before moving on
  #           to the next batch of hosts
  # breadth - run each command on all hosts, in batches, before moving on to
  #           the next command
  #
  # or maybe someone will want a hybrid approach and this should be pushed up
  # into the strategy somehow?

  private

  def execute_depth_traversal!(host_sets, hosts_with_tasks)

    # run all of the commands assigned to the hosts in a host_set then 
    # move on to the next host set. rinse. repeat.

    host_sets.each do |host_set|
      host_set = host_set.dup

      while host_set.any?
        commands_in_set = 0
        host_set.each do |host|
          next unless hosts_with_tasks.has_key?(host)

          if ! task = hosts_with_tasks[host].shift
            host_set.delete(host)
          else
            puts "session.on(#{host}).exec(#{task.command})"
            session.on(@server_map[host]).exec(task.command)
            commands_in_set += 1
          end
        end

        if commands_in_set != 0
          puts "session.loop #{commands_in_set}"
          session.loop 
        end
      end
    end
  end


  def execute_breadth_traversal!(host_sets, hosts_with_tasks)
    # perform whatever tasks have been assigned; i try to do as much as
    # possible in parallel within the terms of the current strategy.
    while hosts_with_tasks.any? 
      host_sets.each do |host_set|
        commands_in_set = 0
        host_set.each do |host|
          if hosts_with_tasks.has_key?(host)
            if task = hosts_with_tasks[host].shift
              commands_in_set += 1
              puts "session.on(#{host}).exec(#{task.command})"
              session.on(@server_map[host]).exec(task.command)
            else
              hosts_with_tasks.delete(host)
            end
          end          
        end
       
        # wait for the work assigned to complete before performing more work.
        if commands_in_set > 0
          puts "session.loop #{commands_in_set}"
          session.loop
        end
      end
    end
  end

end
