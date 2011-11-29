class Hadouken::Strategy::ByHost < Hadouken::Strategy::Base
  def host_strategy
    hosts     = plan.groups.map{|g| g.hosts}.flatten.uniq
    slice     = max_hosts || hosts.size
    host_sets = [] 
    
    slice = max_hosts || hosts.size
    hosts.each_slice(slice) do |host_slice|
      host_sets << host_slice
    end

    host_sets
  end
end
