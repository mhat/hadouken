class Hadouken::Runner

  def self.run
    ts0  = Time.now
    plan = Hadouken::Plan.new
    yield plan
    Hadouken::Executor.run!(plan)
    te0  = Time.now
    Hadouken.logger.info "plan executed in %0.2f" % (te0 - ts0)
  end


end
