require 'open-uri'

module Joyride
  class CloudflareGenerator

    protected attr_reader :log

    public 

    def initialize(log)
      @log = log
    end

    def process(context)
      log.info "looking up public ip address:"

      
      remote_ip = open(ENV.fetch('PUBLIC_IP_API_URL', 'http://whatismyip.akamai.com')).read


      context.domains.each do |domain|
        log.info "\ttemplate => #{domain} #{ENV['HOSTIP']}"
      end

      template.write_template({domains: context.domains})

      log.info "Signaling dnsmasq to reload configuration... "
    end
  end
end