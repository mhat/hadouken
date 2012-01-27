module Net::SSH::Multi::SessionActions

  def hadouken_exec(command)
    open_channel do |channel|

      channel.exec(command) do |ch, success|
        raise "could not execute command: #{command.inspect} (#{ch[:host]})" unless success
        channel.on_data do |ch, data|
          ch[:stdout] = []
          data.chomp.each_line do |line|
            ch[:stdout] << line
          end 
        end 
      end 

      channel.on_extended_data do |ch, type, data|
        ch[:stderr] = []
        data.chomp.each_line do |line|
          ch[:stderr] << line
        end 
      end

      channel.on_request("exit-status") do |ch, data|
        ch[:exit_status] = data.read_long
      end 

    end #open_channel

  end 

end
