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

  def self.any?
    @@hosts.keys.any?
  end

  def self.each
    @@hosts.each do |hostname, host|
      yield host
    end
  end

  def self.disable_all!
    each do |host|
      host.disable! if host.enabled?
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
      @any_failed_commands = false
    end
    def add(command, status, epoch=Time.now.to_f)
      @history << [ command, status, epoch ]
      if !@any_failed_commands
        @any_failed_commands = status != 0
      end
    end
    def any_failed_commands?
      @any_failed_commands
    end
    def each
      @history.each do |command, status, epoch|
        yield command, status, epoch
      end
    end
    def to_json
      history_arr = []
      each do |command, status, epoch|
        history_arr.push({
          :command => command,
          :status => status,
          :time => epoch
        })
      end
      Yajl::Encoder.encode(history_arr)
    end
    def size
      @history.size
    end
  end
end
