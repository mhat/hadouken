module Hadouken::Task
  class Base
    attr_reader :plan
    attr_reader :group_name

    def initialize(opts)
      @group_name = opts[:group] 
      @plan       = opts[:plan ]
    end

    def group?
      !! @group_name
    end

    def group
      @plan.groups.fetch @group_name
    end

    def self.create!(instance, opts)
      return case instance
        # autovivify
        when String then Hadouken::Task::Command.new  instance, opts
        when Array  then Hadouken::Task::Command.new  instance, opts
        when Proc   then Hadouken::Task::Callback.new instance, opts

        # go with it
        when Hadouken::Strategy::Base then instance
        when Hadouken::Task::Base     then instance

        # no chance
        else raise ArgumentError
      end
    end
  end

  class Command < Base
    def initialize(command, opts)
      @command = command
      super(opts)
    end
  
    # TODO: sanitize command so it has a chance of working
    def command
      @command
    end
  end  

  class Callback < Base
    def initialize(fn, opts)
      @proc = fn
      super opts
    end
  
    def call(opts)
      @proc.call(*opts)
    end
  end
end
