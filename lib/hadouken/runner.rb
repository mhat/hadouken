class Hadouken::Runner

  def self.run
    plan = Hadouken::Plan.new
    yield plan
    Hadouken::Executor.run!(plan)
  end

end
