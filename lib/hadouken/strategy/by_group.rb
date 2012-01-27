class Hadouken::Strategy::ByGroup < Hadouken::Strategy::Base
  def host_strategy
    host_sets = []
    plan.groups.each do |group|
      hosts = group.hosts
      slice = max_hosts || hosts.size

      hosts.each_slice(slice) do |host_slice|
        host_sets << host_slice
      end
    end 

    balanced
  end
end
