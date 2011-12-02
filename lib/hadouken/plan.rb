class Hadouken::Plan
  attr_accessor :name
  attr_accessor :root
  attr_accessor :user
  attr_accessor :dry_run
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

end

