require 'helper'

class TestHadouken < Test::Unit::TestCase

  context "yeah" do
    setup do 
      Net::SSH::Multi::Session.any_instance.stubs(:exec).returns(true)
      Net::SSH::Multi::Subsession.any_instance.stubs(:exec).returns(true)
    end

    should "create a group" do 
      g = Hadouken::Group.new(:name => :pony, :range => (1..5), :pattern => "pony-%05d")
      assert_equal g.name,    :pony
      assert_equal g.range,   (1..5)
      assert_equal g.pattern, "pony-%05d"
      assert_equal g.size,    5
      assert_equal g.hosts,   g.range.map{|i| g.pattern % i}
    end

    should "create a collection of groups" do
      plan = Hadouken::Plan.new
      plan.verbose = true
      plan.add_group Hadouken::Group.new(:name => :cat, :range => (1..3), :pattern => "cat-%05d")
      plan.add_group Hadouken::Group.new(:name => :dog, :range => (1..5), :pattern => "dog-%05d")
    
      assert_equal 8, h.groups.hosts.size
      assert_equal h.groups.fetch(:cat), h.groups[:cat]
      assert_equal 'cat-00003', h.groups.fetch(:cat).hosts.last
      assert_equal 'dog-00005', h.groups.fetch(:dog).hosts.last
    end

    should "use by-host strategy" do
      plan = Hadouken::Plan.new
      plan.verbose = true
      plan.add_group Hadouken::Group.new(:name => :cat, :range => (1..3), :pattern => "cat-%05d")
      plan.add_group Hadouken::Group.new(:name => :dog, :range => (1..3), :pattern => "dog-%05d")

      cats  = (1..3).map{|i| "cat-%05d" % i}
      dogs  = (1..3).map{|i| "dog-%05d" % i}
      crazy = [ cats + dogs ]

      servers = Hadouken::Strategy::ByHost.new(plan).host_strategy
      assert_equal crazy, servers
    end

    should "use by-host strategy with two at a time" do
      plan = Hadouken::Plan.new
      plan.verbose = true
      plan.add_group Hadouken::Group.new(:name => :cat, :range => (1..3), :pattern => "cat-%05d")
      plan.add_group Hadouken::Group.new(:name => :dog, :range => (1..3), :pattern => "dog-%05d")

      cats  = (1..3).map{|i| "cat-%05d" % i}
      dogs  = (1..3).map{|i| "dog-%05d" % i}
      crazy = []
      (cats + dogs).each_slice(2) do |s|
        crazy << s
      end

      servers = Hadouken::Strategy::ByHost.new(plan, :max_hosts => 2).host_strategy
      assert_equal crazy, servers
    end


    should "use by-group strategy with two at a time" do
      plan = Hadouken::Plan.new
      plan.verbose = true
      plan.add_group Hadouken::Group.new(:name => :cat, :range => (1..3), :pattern => "cat-%05d")
      plan.add_group Hadouken::Group.new(:name => :dog, :range => (1..3), :pattern => "dog-%05d")

      cats = (1..3).map{|i| "cat-%05d" % i}
      dogs = (1..3).map{|i| "dog-%05d" % i}

      servers = Hadouken::Strategy::ByGroup.new(plan, :max_hosts => 2).host_strategy
      assert_equal cats[0..1], servers[0]
      assert_equal [cats[2]],  servers[1]
      assert_equal dogs[0..1], servers[2]
      assert_equal [dogs[2]],  servers[3]
    end

    
    should "use by-group-parallel strategy" do
      plan = Hadouken::Plan.new
      plan.verbose = true
      plan.name = :pet_store
      plan.add_group Hadouken::Group.new(:name => :cat, :range => (1..3), :pattern => "cat-%05d")
      plan.add_group Hadouken::Group.new(:name => :dog, :range => (1..3), :pattern => "dog-%05d")
      plan.add_group Hadouken::Group.new(:name => :hog, :range => (1..3), :pattern => "hog-%05d")

      cats  = (1..3).map{|i| "cat-%05d" % i}
      dogs  = (1..3).map{|i| "dog-%05d" % i}
      hogs  = (1..3).map{|i| "hog-%05d" % i}

      crazy  = []
      crazy << [ cats[0], dogs[0], hogs[0] ]
      crazy << [ cats[1], dogs[1], hogs[1] ]
      crazy << [ cats[2], dogs[2], hogs[2] ]

      plan.tasks << Hadouken::Strategy::ByHost.new(plan)
      plan.tasks << Hadouken::Task::Command.new("aaa", :plan => plan)
      plan.tasks.store "bbb", :plan => plan
      plan.tasks.store Proc.new{|host|
      }, :plan => plan

      plan.tasks << Hadouken::Strategy::ByGroupParallel.new(plan, :max_hosts => 4, :traversal => :depth)
      plan.tasks << Hadouken::Task::Command.new("doggie", :plan => plan, :group_name => :dog)
      plan.tasks << Hadouken::Task::Command.new("kitty",  :plan => plan, :group_name => :cat)
      plan.tasks << Hadouken::Task::Command.new("pig",    :plan => plan, :group_name => :hog)
      plan.tasks.store Proc.new{|host|
        puts "**************** #{host} ******************"
      }, :plan => plan

      Hadouken::Executor.run!(plan)
    end



  end
end
