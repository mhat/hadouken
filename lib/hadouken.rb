module Hadouken; end;
module Hadouken::Strategy; end;

require 'hadouken/executor'
require 'hadouken/group'
require 'hadouken/groups'
require 'hadouken/host'
require 'hadouken/strategy/base'
require 'hadouken/strategy/by_host'
require 'hadouken/strategy/by_group'
require 'hadouken/strategy/by_group_parallel'
require 'hadouken/task'
require 'hadouken/tasks'

require 'net/ssh/multi'

class Hadouken::Plan
  attr_accessor :name
  attr_accessor :base
  attr_accessor :user

  attr_accessor :dry_run
  attr_accessor :verbose
  
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

  def add_task(t, opts)
    @tasks.store(t, opts)
  end

  def dry_run?
    !!@dry_run
  end

  def verbose?
    !!@verbose
  end

end

module Hadouken
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end
end
