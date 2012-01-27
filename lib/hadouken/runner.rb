class Hadouken::Runner

  attr_accessor :args
  attr_accessor :plan

  def initialize
    @args = self.class.optparse
    @plan = Hadouken::Plan.new
    @plan.environment = @args[:environment]
    @plan.dry_run     = @args[:dry_run]
    @plan.interactive = @args[:interactive]
    @plan.planfile    = @args[:planfile]
    @plan.artifact    = @args[:artifact]
  end

  def self.run!
    runner = Hadouken::Runner.new
    plan   = runner.plan

    yield(plan)

    ts0  = Time.now
    Hadouken::Executor.run!(plan)
    te0  = Time.now

    Hadouken.logger.info "plan executed in %0.2f" % (te0 - ts0)
  end

  def self.optparse
    args   = {}
    parser = OptionParser.new do |opts|
      opts.banner  = "Usage: #{$0} [options]"
      opts.separator ""
      opts.separator "options:"
      
      opts.on("--interactive",   "output stdout/stderr to console") {|o| args[:interactive] = o}
      opts.on("--dry-run",       "take no action"                 ) {|o| args[:dry_run]     = o}
      opts.on("--env ENV",       "stage|production|ding-dong|..." ) {|o| args[:environment] = o}

      opts.on("--history PATH",  "where to store history files") do |o| 
        args[:history] = o || 'history'
        FileUtils.mkdir_p args[:history]
        Hadouken::Hosts.history_filepath = args[:history]
      end

      opts.on("--artifact URL", "URL to the service artifact" ) do |o|
        begin
          args[:artifact] = URI.parse(o)
          raise URI::InvalidURIError unless args[:artifact].is_a?(URI::HTTP)
        rescue URI::InvalidURIError
          puts "Sorry, invalid artifact url: #{o}"
          exit 1
        end
      end

      opts.on("--level LEVEL",  "debug|info|warn|error|fatal" ) do |o|
        if o !~ /^(debug|info|warn|error|fatal)$/i
          puts "Sorry, I don't know what that log level is ..."
          exit -1
        else
          args[:level] = case o.downcase
            when /debug/ then Logger::DEBUG
            when /info/  then Logger::INFO
            when /warn/  then Logger::WARN
            when /error/ then Logger::ERROR
            when /fatal/ then Logger::FATAL
          end 
        end

        Hadouken.logger.level = args[:level] || Logger::INFO
      end
    end
    parser.parse!

    unless args.has_key?(:artifact) &&
           args.has_key?(:environment)
      puts parser
      exit 1
    end

    return args    
  end

end
