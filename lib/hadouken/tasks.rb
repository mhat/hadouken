class Hadouken::Tasks
  include Enumerable

  def initialize
    @tasks = []
  end

  def each
    @tasks.each do |task|
      yield task
    end
  end

  def << (task, opts={})
    store task, opts
  end

  def store(task, opts={})
    @tasks << Hadouken::Task::Base.create!(task, opts)
  end
end
