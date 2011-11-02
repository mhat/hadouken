class Hadouken::Strategy::Base
  attr_reader :plan
  attr_reader :max_hosts
  attr_reader :traversal

  def initialize(plan, opts={})
    @plan      = plan
    @max_hosts = opts[:max_hosts]
    @traversal = opts[:traversal] || :breadth
  end

  def host_strategy
    raise ArgumentError, "not implemneted here"
  end
end
