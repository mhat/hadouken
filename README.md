hadouken - soon

### running

    ./serviceie.rb --interactive \ 
                 --level debug \
                 --environment production \
                 --history /opt/deploys   \
                 --artifact https://artifacts/latest.tgz


### serviceie.rb

    Hadouken::Runner.run!
      plan      = Hadouken::Plan.new
      plan.name = "serviceie"
      plan.user = "serviceie"
      plan.base = "/opt/serviceie"
   
      # define some groups 10x10
      #
      plan.add_group :web, :range => (1..10), :pattern => 'serviceie-web-%02d.example.com'
      plan.add_group :api, :range => (1..10), :pattern => 'serviceie-api-%02d.example.com'


      # download latest.tgz from our artifact repository
      # runs in parallel on all hosts
      #
      plan.tasks.add Hadouken::Strategy::ByHost.new(plan)
      plan.tasks.add "curl -sSfL -output /tmp/latest.tgz #{artifact}"
      plan.tasks.add "mv /tmp/latest.tgz #{plan.base}/latest.tgz"


      # runs commands depth first on the api hosts, two at a time
      # - restart service
      # - verify  service
      #
      plan.tasks.add Hadouken::Strategy::ByHost.new(plan, :max_hosts => 2, :traversal => :depth)
      plan.tasks.add "restart serviceie-api", :group => :api
      plan.tasks.add Proc.new { |opts|
        host = opts[:host]
        10.times do
          response = Typhous::Request.get("http://#{host}:8081/healthcheck")
          break if response.status_code == 200
        end
      }, :group => :api

      
      # finally restart the webs as fast as possible
      #
      plan.tasks.add Hadouken::Strategy::ByHost.new(plan)
      plan.tasks.add "restart windard-web, :group => :web
    end


