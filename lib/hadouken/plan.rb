class Hadouken::Plan
  attr_accessor :name
  attr_accessor :root
  attr_accessor :user

  attr_accessor :environment
  attr_accessor :dry_run
  attr_accessor :interactive

  attr_accessor :history_path
  attr_accessor :planfile
  attr_accessor :artifact

  attr_reader   :timestamp
  
  def initialize
    @tasks     = Hadouken::Tasks.new
    @groups    = Hadouken::Groups.new
    @timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def groups
    @groups
  end

  def tasks
    @tasks
  end

  def dry_run?
    !!@dry_run
  end

  def interactive?
    !!@interactive
  end

  def env
    environment
  end


  def logger
    Hadouken.logger
  end

end

