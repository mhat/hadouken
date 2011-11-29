module Hadouken::Hosts
  @@hosts = {}

  def self.add(hostname)
    @@hosts[hostname] ||= Hadouken::Host.new(hostname)
  end
  
  def self.get(hostname)
    @@hosts[hostname]
  end

  def self.exists?(hostname)
    @@hosts.exists?(hostname)
  end

  def self.count
    @@hosts.keys.count
  end

  def self.each
    @@hosts.each do |hostname, host|
      yield host
    end
  end
end

class Hadouken::Host
  attr_reader   :name
  attr_reader   :history
  attr_accessor :server

  def initialize(name)
    @name    = name
    @enabled = true
    @history = History.new
  end

  def disable!
    history.add :disabled, :noop
    @enabled = false
  end

  def enable!
    history.add :enabled,  :noop
    @enabled = true
  end

  def enabled?
    @enabled
  end

  def to_s
    name
  end

  class History
    def initialize
      @history = []
    end
    def add(command, status, epoch=Time.now.to_f)
      @history << [ command, status, epoch ]
    end
    def each
      @history.each do |command, status, epoch|
        yield command, status, epoch
      end
    end
  end
end
