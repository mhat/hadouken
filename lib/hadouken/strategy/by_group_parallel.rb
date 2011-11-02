class Hadouken::Strategy::ByGroupParallel < Hadouken::Strategy::Base
  def host_strategy


    return @balanced if @balanced

    # transform a array of groups, hosts into a new array that balances
    # hosts from each group into a single array.

    @balanced = []
    regroup  = []
    groups   = []
    max_size =  0

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

    slice = max_hosts || balanced.size
    regroup.each_slice(slice) do |host_slice|
      @balanced << host_slice
    end

    @balanced
  end
end
