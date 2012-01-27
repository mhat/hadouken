class Hadouken::Strategy::ByGroupParallel < Hadouken::Strategy::Base
  def host_strategy
    return @host_sets if @host_sets

    # transform a array of groups, hosts into a new array that balances
    # hosts from each group into a single array.
    @host_sets = []
    regroup    = []
    groups     = []
    max_size   =  0

    plan.groups.each do |group|
      hosts     = group.hosts
      max_size  = [max_size, hosts.size].max
      groups   << hosts
    end

    [max_size, groups.size].max.times do  
      groups.each do |hosts|
        if hosts.size == 0
          #TODO groups.delete(name)
        else
          regroup << hosts.shift
        end
      end
    end

    regroup.each_slice(max_size) do |host_slice|
      @host_sets << host_slice
    end

    @balanced
  end
end
