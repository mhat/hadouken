class Hadouken::Runner

  attr_reader :plan
  attr_reader :env
  attr_reader :history


  def initialize(name)
    @plan      = Hadouken::Plan.new
    @plan.name = name
    @args      = self.class.optparse
    @env       = @args[:env]

    @plan.dry_run         = true          if @args[:dry_run]
    Hadouken.logger.level = @args[:level] || Logger::INFO
  end


  def config
    @config_file ||= "config/#{plan.name}/#{env}.yml"
    @config      ||= begin
      Hadouken.logger.info "using configuration in #{ @config_file }"
      YAML.load_file(@config_file)
    rescue => e
      Hadouken.logger.warn "missing #{ @config_file }"
      {} 
    end
  end


  def self.run(name)
    runner = Hadouken::Runner.new(name)
    plan   = runner.plan
    history_filepath = "history/#{plan.name}/#{runner.env}/#{Time.now.to_i}"
    Hadouken::Host.history_filepath = history_filepath
    FileUtils.mkdir_p(history_filepath)

    # populate groups from config
    runner.config.sort{|a,b| a.to_s <=> b.to_s}.each do |group, opts|
      range   = opts[:start]..opts[:stop]
      pattern = opts[:pattern]
      Hadouken.logger.debug "runner: g=#{group}, p=#{pattern}, r=#{range}"
      plan.groups.add group, :range => range, :pattern => pattern
    end

    yield plan

    ts0  = Time.now
    Hadouken::Executor.run!(plan)
    te0  = Time.now

    Hadouken.logger.info "plan executed in %0.2f" % (te0 - ts0)
  end

  def self.optparse
    args = {}

    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ""
      opts.separator "options:"
      
      opts.on("--env ENV",      "stage|thunderdome|production" ) {|o| args[:env    ] = o }
      opts.on("--dry-run",      "take no action"               ) {|o| args[:dry_run] = o }
      opts.on("--level LEVEL",  "debug|info|warn|error|fatal"  ) do |o|
        if o !~ /^(debug|info|warn|error|fatal)$/i
          puts "Sorry, I don't know what that log level is ..."
          exit -1
        else
          args[:level] = case o.downcase
            when /debug/ : Logger::DEBUG
            when /info/  : Logger::INFO
            when /warn/  : Logger::WARN
            when /error/ : Logger::ERROR
            when /fatal/ : Logger::FATAL
          end 
        end
      end
    end.parse!

    return args    
  end

end
