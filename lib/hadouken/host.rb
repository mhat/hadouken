module Hadouken::Hosts

  class << self
    attr_accessor :history_filepath
  end

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

  # used to store the net-ssh server object
  attr_accessor :server

  def initialize(opts={})
    @name    = opts[:name]
    @enabled = true
    @history = History.new(self)
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
 
  def history_filepath
    File.join(Hadouken::Hosts.history_filepath, "#{name}.log")
  end
 

  class History
    include Enumerable

    def initialize(host)
      @host     = host
      @history  = []
    end

    def add(command, status, stdout=nil, stderr=nil, epoch=Time.now.to_f)
      stdoutJoined = stdout ? stdout.join("\n") : nil
      stderrJoined = stderr ? stderr.join("\n") : nil
      @history << [command, status, epoch, stdoutJoined, stderrJoined]
      File.open(@host.history_filepath, 'a') do |history_file|
        history_file.write(Yajl::Encoder.encode(command_to_hash(command, status, epoch, stdoutJoined, stderrJoined)))
        history_file.write("\n")
      end
    end

    def each
      @history.each do |command, status, epoch, stdout, stderr|
        yield command, status, epoch, stdout, stderr
      end
    end

    def to_json
      Yajl::Encoder.encode self.map do |command, status, epoch, stdout, stderr|
        command_to_hash(command, status, epoch, stdout, stderr)
      end
    end

    private

    def command_to_hash(command, status, epoch, stdout, stderr)
      return {
        :command => command,
        :status  => status,
        :time    => (epoch * 1000).round,
        :stdout  => stdout,
        :stderr  => stderr
      }
    end
  end
end
