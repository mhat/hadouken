class Hadouken::Plan
  attr_accessor :name
  attr_accessor :root
  attr_accessor :user
  attr_accessor :dry_run
  
  def initialize
    @tasks  = Hadouken::Tasks.new
    @groups = Hadouken::Groups.new
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

