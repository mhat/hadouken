module Hadouken; end;
module Hadouken::Strategy; end;

require 'hadouken/executor'
require 'hadouken/group'
require 'hadouken/groups'
require 'hadouken/strategy/base'
require 'hadouken/strategy/by_host'
require 'hadouken/strategy/by_group'
require 'hadouken/strategy/by_group_parallel'

require 'net/ssh/multi'

class Hadouken::Plan
  attr_accessor :name
  attr_accessor :base
  attr_accessor :user
  
  def initialize
    @tasks  = Hadouken::Tasks.new
    @groups = Hadouken::Groups.new
  end

  def groups
    @groups
  end

  def add_group(g)
    @groups.store(g)
  end

  def tasks
    @tasks
  end

  def add_task(t)
    @tasks.store(t)
  end


  def wait
  end
end



class Hadouken::Tasks
  include Enumerable

  def initialize
    @tasks = []
  end

  def each
    @tasks.each do |task|
      yield task
    end
  end

  def << (task)
    store task
  end

  def store(task)
    ## FIXME
    @tasks << task #case task.class
    ##  when String                   : Hadouken::Task.new(task)
    ##  when Array                    : Hadouken::Task.new(task)
    ##  when Hadouken::Strategy::Base : task
    ##  when Hadouken::Task           : task  
    ##  else raise ArgumentError.new("unknown task_class=#{task.class}")
    ##end
  end
end

class Hadouken::Task
  attr_reader :command
  attr_reader :group_name
  attr_reader :plan
  
  def initialize(opts)
    @group_name = opts[:group_name]
    @plan       = opts[:plan]
    @command    = opts[:command] #case opts[:command].class
    ## FIXME
    ##  when Proc   : opts[:command] 
    ##  when String : opts[:command] 
    ##  when Array  : opts[:command].join(" && ")
    ##  else          raise ArgumentError
    ##end
  end

  def group
    plan.groups.fetch(group_name)
  end

  def group_task?
    !! @group_name
  end
end




