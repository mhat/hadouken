class Hadouken::Strategy::ByHost < Hadouken::Strategy::Base
  def host_strategy
    hosts    = plan.groups.map{|g| g.hosts}.flatten.uniq
    slice    = max_hosts || hosts.size
    balanced = [] 
    
    slice = max_hosts || hosts.size
    hosts.each_slice(slice) do |host_slice|
      balanced << host_slice
    end

    balanced
  end
end
