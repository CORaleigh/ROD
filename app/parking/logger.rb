#logger.rb  => space.log

require 'logger'

log_file = File.new("space.log", 'a+')
log_file.sync = true

LOGGER = Logger.new(log_file, 'weekly')
LOGGER.level = Logger::INFO