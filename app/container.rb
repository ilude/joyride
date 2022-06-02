module Joyride
  class Container
    attr_reader :domain, :container

    def initialize(container)
      self.container = container
      self.domain = container.info["Labels"][Joyride::HostnameLabel]
    end

    def to_s
      self.domain
    end
  end
end