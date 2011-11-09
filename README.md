hadouken - soon


    plan      = Hadouken::Plan.new
    plan.name = "wizardie"
    plan.user = "wizardie"
    plan.base = "/opt/drop_wizardie"
   
    # do nothing, but be verbose about it
    plan.verbose = true
    plan.dry_run = true
   
    # define some groups 10x10
    #
    plan.add_group :web, :range => (1..10), :pattern => 'wizardie-web-%02d.example.com'
    plan.add_group :api, :range => (1..10), :pattern => 'wizardie-api-%02d.example.com'


    # download latest.tgz from our artifact repository
    # runs in parallel on all hosts
    #
    plan.tasks.add Hadouken::Strategy::ByHost.new(plan)
    plan.tasks.add "curl -sSfL -output /tmp/latest.tgz https://artifact.repository.example.com/latest.tgz"
    plan.tasks.add "mv /tmp/latest.tgz #{plan.base}/latest.tgz"


    # runs commands depth first on the api hosts, two at a time
    # - restart service
    # - verify  service
    #
    plan.tasks.add Hadouken::Strategy::ByHost.new(plan, :max_hosts => 2, :traversal => :depth)
    plan.tasks.add "restart wizardie-api", :group => :api
    plan.tasks.add Proc.new { |host|
      10.times do
        response = Typhous::Request.get("http://#{host}:8081/healthcheck")
        break if response.status_code == 200
      end
    }, :group => :api
    
    # finally restart the webs as fast as possible
    #
    plan.tasks.add Hadouken::Strategy::ByHost.new(plan)
    plan.tasks.add "restart windard-web, :group => :web
    
    plan.run!
    
