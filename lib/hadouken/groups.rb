class Hadouken::Groups
  include Enumerable

  def initialize
    @groups = {}
    @order  = []
  end

  def count
    @groups.values.size
  end
  alias :size :count

  def hosts
    @groups.values.map{|group| group.hosts}.flatten
  end

  def each
    @order.uniq!
    @order.each do |name|
      yield @groups[name]
    end
  end

  def [](name)
    fetch name
  end

  def fetch (name)
    @groups[ name ]
  end

  def add (name, opts)
    store(Hadouken::Group.create!(name, opts))
  end

  def store (group)
    raise ArgumentError.new("8==D~") unless group.is_a?(Hadouken::Group)
    @groups[ group.name ] = group
    @order << group.name
  end
end
