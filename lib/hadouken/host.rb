module Hadouken::Hosts
  @@hosts = {}

  def self.add(opts={})
    @@hosts[opts[:name]] ||= Hadouken::Host.new(opts)
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

  def initialize(opts={})
    @name    = opts[:name]
    @enabled = true
    @history = History.new({:history_filepath => "#{opts[:history_filepath]}/#{@name}"})
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
    def initialize(opts={})
      @history_filepath = "#{opts[:history_filepath]}.log"
      @history = []
    end
    def add(command, status, epoch=Time.now.to_f)
      @history << [ command, status, epoch ]
      File.open(@history_filepath, 'a') do |history_file|
        history_file.write(Yajl::Encoder.encode(command_to_hash(command, status, epoch)))
        history_file.write("\n")
      end
    end
    def each
      @history.each do |command, status, epoch|
        yield command, status, epoch
      end
    end
    def to_json
      history_arr = []
      each do |command, status, epoch|
        history_arr.push(command_to_hash(command, status, epoch))
      end
      Yajl::Encoder.encode(history_arr)
    end

    private

    def command_to_hash(command, status, epoch)
      {
        :command => command,
        :status  => status,
        :time    => epoch
      }
    end
  end
end
