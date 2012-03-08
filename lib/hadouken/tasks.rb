class Hadouken::Tasks
  include Enumerable

  attr_reader :plan

  def initialize(opts)
    @plan  = opts[:plan]
    @tasks = []
  end

  def each
    @tasks.each do |task|
      yield task
    end
  end

  def add(task, opts={})
    @tasks << Hadouken::Task::Base.create!(task, {:plan => plan}.merge(opts))
  end
end
