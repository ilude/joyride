require 'open-uri'

module Joyride
  class CloudflareGenerator
    include Joyride::Logger

    UpdateLabel = "joyride.cloudflare.update".freeze
    PublicIPLabel = "joyride.cloudflare.public.ip".freeze
    ProxyLabel = "joyride.cloudflare.proxy".freeze

    def initialize()
      log.warn {"Required environment variable CLOUDFLARE_API_TOKEN is missing! Cloudflare DNS will NOT be updated!"} if cloudflare_api_token.empty?
    end

    def public_ip_address(container)
      return container.info["Labels"][PublicIPLabel] unless container.info["Labels"][PublicIPLabel].nil? || container.info["Labels"][PublicIPLabel].empty?

      open(ENV.fetch('PUBLIC_IP_API_URL', 'http://whatismyip.akamai.com')).read
    end

    def proxied?(container)
      proxied = container.info["Labels"][ProxyLabel]
      return (proxied.nil? == false && (proxied.downcase.eql?('true') || proxied.downcase.eql?('yes'))
    end

    def cloudflare_api_token()
      ENV.fetch('CLOUDFLARE_API_TOKEN')
    end

    def process(containers)  
      return if cloudflare_api_token.empty?

      connection = Rubyflare.connect_with_token(cloudflare_api_token)

      containers.uniq{|container| container.to_s }.each do |container|
        log.debug {"starting cloudflare registration for: #{container.domain}"}
        
      zone_name = PublicSuffix.domain(container.domain)
      zone_id = connection.get('zones', { name: zone_name }).result[:id]

      result = connection.post("zones/#{zone_id}/dns_records", {
        type: 'A',
        name: container.domain,
        content: public_ip_address(container),
        proxy: proxied?(container)
        })
      
      log.debug {"cloudflare registration for: #{container.domain} success: #{result.success} #{result.error}"}
      end
    end
  end
end