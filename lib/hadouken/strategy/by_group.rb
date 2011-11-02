class Hadouken::Strategy::ByGroup < Hadouken::Strategy::Base
  def host_strategy
    balanced = []
    plan.groups.each do |group|
      hosts = group.hosts
      slice = max_hosts || hosts.size

      hosts.each_slice(slice) do |host_slice|
        balanced << host_slice
      end
    end 

    balanced
  end
end
