module Joyride

  # no buffering output
  $stdout.sync = true
  
  log = Logger.new($stdout)
  log.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
  log.info "Beginning Joyride..."

  Log = log
  
  class Logger
    protected

    def log()
      Joyride::Log
    end
  end
end