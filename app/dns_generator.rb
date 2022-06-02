require 'erb'

module Joyride
  class DnsGenerator
    include Joyride::Logger
    
    attr_reader :template, :dnsmasq_process

    def initialize()
      self.template = Template.new("/etc/dnsmasq.d/hosts", "/app/templates/dnsmasq.hosts.erb", log)

      # write out basic dnsmasq.conf
      Template.new("/etc/dnsmasq.conf", "/app/templates/dnsmasq.conf.erb", log).write_template()

      #start dnsmasq
      log.info "Starting dnsmasq..."
      self.dnsmasq_process = fork { exec "/usr/sbin/dnsmasq" }
    end

    def process(containers)
      domains = containers.uniq{|container| container.to_s }

      log.info "Generating dnsmasq config with hosts:"
      domains.each do |domain|
        log.info "\ttemplate => #{domain} #{ENV['HOSTIP']}"
      end

      template.write_template({domains: domains})

      log.info "Signaling dnsmasq to reload configuration... "
      Process.kill("HUP", self.dnsmasq_process)
    end
  end
end