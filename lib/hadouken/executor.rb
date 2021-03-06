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

    if Hadouken::Hosts.any?
      exec.execute!
    else
      Hadouken.logger.error "No hosts have been defined, this deploy is boring!"
    end
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
 
      if task.is_a?(Hadouken::Task::Base)
        @phases.last.tasks << task
      end
    end

    @phases
  end 

  def session
    @session ||= session!
  end

  def session!
    @session = Net::SSH::Multi.start(:on_error => Proc.new{ |server|
      host = Hadouken::Hosts.get(server.host)
      Hadouken.logger.debug "error with #{server.host}, disabling"
      host.history.add "ssh.connection.new", :fail
      host.disable!
    })

    plan.groups.each do |group|
      group.hosts.each do |host|
        unless host.server
          Hadouken.logger.debug "session.use #{plan.user}@#{host}"
          server      = session.use "#{plan.user}@#{host}"
          host.server = server
        end
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
      Hadouken.logger.info "idx:#{phase_index}, strategy=#{strategy}"

      ## assign work
      host_sets.each do |host_set|
        Hadouken.logger.info "hosts=#{host_set.join(', ')}"
      
        host_set.each do |host|
          hosts_with_tasks[host] ||= []

          phase.tasks.each do |task|
            # if this is not a group task then assign it to the host OR if
            # this is a group task and the host is part of the task-group,
            # then assign the task to the host
            if !task.group? || (task.group? && task.group.has_host?(host))
              hosts_with_tasks[host] <<  task
            end
          end
        end
      end

      case strategy.traversal
        when :breadth then execute_breadth_traversal! host_sets, hosts_with_tasks
        when :depth   then execute_depth_traversal!   host_sets, hosts_with_tasks
        else raise RuntimeError, "unknown tranversal=#{strategy.traversal}"
      end
    end
  end

  private
  def execute_depth_traversal!(host_sets, hosts_with_tasks)
    # run all of the commands assigned to the hosts in a host_set then 
    # move on to the next host set. rinse. repeat.

    host_sets.each do |host_set|
      while hosts_with_tasks.values_at(*host_set.map).select{|t| t.any?}.any?
        channels = []
        host_set.each do |host|
          # not all hosts will necessarily have the same number of tasks
          next unless hosts_with_tasks[host].any?
          next unless task = hosts_with_tasks[host].shift

          case task
            when Hadouken::Task::Callback then Hadouken.logger.debug "callback for #{host}"
            when Hadouken::Task::Command  then Hadouken.logger.debug "session.on(#{host}).exec(#{task.command})"
          end

          if ! plan.dry_run?
            if ! host.enabled?
              case task
                when Hadouken::Task::Callback then host.history.add task.to_s,    :noop
                when Hadouken::Task::Command  then host.history.add task.command, :noop
              end
            else
              case task
              when Hadouken::Task::Callback
                ret = task.call({:host => host})
                host.history.add task.to_s, ret
                host.disable! unless ret == 0

              when Hadouken::Task::Command
                Hadouken.logger.info "running #{task.command} on #{host}"
                channels << [task.command, session.on(host.server).hadouken_exec(task.command)]
              end
            end
          end
        end

        # wait for the work assigned to complete before performing more work.
        wait_on_channels(channels)

      end # while hosts_with_tasks
    end # host_sets.each
  end 


  def execute_breadth_traversal!(host_sets, hosts_with_tasks)
    # perform whatever tasks have been assigned; i try to do as much as
    # possible in parallel within the terms of the current strategy.

    while hosts_with_tasks.any?

      host_sets.each do |host_set|
        channels = []
        host_set.each do |host|
          if hosts_with_tasks.has_key?(host)

            unless task = hosts_with_tasks[host].shift
              # remove the host from hosts-with-tasks when there are no more tasks!
              hosts_with_tasks.delete(host)
            else
              case task
                when Hadouken::Task::Callback then Hadouken.logger.debug "callback for #{host}"
                when Hadouken::Task::Command  then Hadouken.logger.debug "session.on(#{host}).exec(#{task.command})"
              end

              if ! plan.dry_run?
                if ! host.enabled?
                  case task
                    when Hadouken::Task::Callback then host.history.add task.to_s,    :noop
                    when Hadouken::Task::Command  then host.history.add task.command, :noop
                  end
                else 
                  case task
                  when Hadouken::Task::Callback
                    ret = task.call({:host => host})
                    host.history.add task.to_s, ret
                    host.disable! unless ret == 0
                  when Hadouken::Task::Command
                    Hadouken.logger.info "running #{task.command} on #{host}"
                    channels << [task.command, session.on(host.server).hadouken_exec(task.command)]
                  end
                end
              end
            end
          end
        end

        # wait for the work assigned to complete before performing more work.
        wait_on_channels(channels)

      end # host_sets.each
    end # while
  end

  def wait_on_channels(channels)
    if channels.count > 0
      Hadouken.logger.info "waiting for #{channels.count} commands to execute"
      return if plan.dry_run?

      session.loop
      channels.each do |command, channel|
        channel.each do |subchannel|
          host = Hadouken::Hosts.get(subchannel[:host])
          host.history.add(command, subchannel[:exit_status], subchannel[:stdout], subchannel[:stderr])
          if plan.interactive?
            Hadouken.logger.info "[STDOUT] - #{host.name}: %s" % [ subchannel[:stdout].join("\n") ] if subchannel[:stdout]
            Hadouken.logger.warn "[STDERR] - #{host.name}: %s" % [ subchannel[:stderr].join("\n") ] if subchannel[:stderr]
          end

          unless subchannel[:exit_status] == 0
            Hadouken.logger.debug "got status=#{subchannel[:exit_status]} on #{subchannel[:host]}"
            host.disable!
          end
        end
      end
    end 
  end


end
