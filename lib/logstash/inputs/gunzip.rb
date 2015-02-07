# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

require "pathname"
require "socket" # for Socket.gethostname

# Stream events from gz files.
class LogStash::Inputs::Gunzip < LogStash::Inputs::Base

        config_name "gunzip"

        milestone 1

        default :codec, "plain"

        # Gz file path
        config :path, :validate => :array, :required => true

        # Ignore lines below the :tail
        config :tail, :validate => :number, :default => 0

        # Ignore lines above the :head
        config :head, :validate => :number, :default => 0

        # Ignore lines below the delimiter line
        config :delimiter, :validate => :string, :default => ""

        # Open gz files
        public
        def register
                @hostname = Socket.gethostname
                @gzstream = {}
                @path.each do |path|
                        @logger.info("Opening file", :path => path)
                        @gzstream[path] = Zlib::GzipReader.new(open(path), {"encoding"=>@codec.charset})
                end
        end # def register

        public
        def run(queue)
                @path.each do |path|
                        lineNumber = 0
                        @gzstream[path].each_line do |line|
                                lineNumber = lineNumber+1
                                if lineNumber>=@head and (@tail == 0 or lineNumber<=@tail)
                                        if @delimiter != "" and @delimiter == line.chomp
                                                break
                                        end
                                        @codec.decode(line) do |event|
                                                decorate(event)
                                                event["host"] = @hostname if !event.include?("host")
                                                event["path"] = path
                                                event["line_number"] = lineNumber
                                                queue << event
                                        end
                                end
                        end
                end
                sleep(10)
                finished
        end # def run

end # class LogStash::Inputs::Gunzip
