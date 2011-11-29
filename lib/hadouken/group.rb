class Hadouken::Group
  attr_reader :name
  attr_reader :range
  attr_reader :pattern

  def initialize(opts)
    @name    = opts[:name]
    @range   = opts[:range]
    @pattern = opts[:pattern]
  end

  def count
    @count  ||= hosts.size
  end
  alias :size :count

  def hosts
    @hosts ||= @range.map{|idx| "#{@pattern}" % [ idx ] }.map do |hostname|
      Hadouken::Hosts.add(hostname)
    end
  end

  def has_host?(name)
    @hosts_by_name ||= hosts.inject({}){|h,host| h[host]=true; h}
    @hosts_by_name.has_key?(name)
  end

end
