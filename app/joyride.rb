#!/usr/bin/env ruby
require 'docker'
require 'json'
require 'logger'
require 'rufus-scheduler'

require_relative 'logger'
require_relative 'template'
require_relative 'dns_generator'

updated_at = Time.now.to_i

module Joyride
  HostnameLabel = "joyride.host.name".freeze
  ContainerFilter = { status: ["running"], label: [HostnameLabel]  }.to_json.freeze
  Mutex = Mutex.new
end

generators = [Joyride::DnsGenerator.new(), Joyride::CloudflareGenerator.new()] 

scheduler = Rufus::Scheduler.new

scheduler.every '3s', :first => :now, :mutex => Joyride::Mutex do
  # we are only intereseted in container start,stop and die events
  # and those containers must have a HostnameLabel
  event = []
  Docker::Event.since(updated_at, until: updated_at = Time.now.to_i) {|event| events << event}
  events.select!{|event| 
      event.type.eql?("container") && 
      ["start", "stop", "die"].include?(event.action) && 
      event.actor.attributes.has_key?("joyride.host.name")
  }

  return if events.empty?
  


  containers = Docker::Container.all(all: true, filters: ContainerFilter)
    .map{|container| Joyride::Container.new(container) }

  generators.each{|generator| generator.process(containers)}
end

Kernel.trap( "INT" ) do 
  scheduler.shutdown
  log.info "Joyride has ended!"
end

scheduler.join()