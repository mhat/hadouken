module Hadouken; end;
module Hadouken::Strategy; end;

require 'rubygems'
require 'fileutils'
require 'yajl'
require 'uri'
require 'net/ssh/multi'

require 'hadouken/executor'
require 'hadouken/group'
require 'hadouken/groups'
require 'hadouken/host'
require 'hadouken/plan'
require 'hadouken/runner'
require 'hadouken/strategy/base'
require 'hadouken/strategy/by_host'
require 'hadouken/strategy/by_group'
require 'hadouken/strategy/by_group_parallel'
require 'hadouken/task'
require 'hadouken/tasks'

require 'hadouken/ext/net_ssh_multi_session_actions'

module Hadouken
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end
end
