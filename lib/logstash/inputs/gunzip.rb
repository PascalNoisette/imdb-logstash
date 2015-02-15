#
# imdb-logstash
#
# Copyright © 2015 Pascal NOISETTE
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

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
        config :path, :required => true

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
                @path.each do |path, cnf|
                        @logger.info("Opening file", :path => path)
                        @gzstream[path] = Zlib::GzipReader.new(open(path), {"encoding"=>@codec.charset})
                end
        end # def register
        
        public
        def run(queue)
                @path.each do |path, cnf|
                        @tail = cnf["tail"] if cnf.include?("tail")
                        @head = cnf["head"] if cnf.include?("head")
                        @delimiter = cnf["delimiter"] if cnf.include?("delimiter")
                        lineNumber = 0
                        sleep(1) while queue.length > 0 # make sure the previous file has been processed
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
                                if @tail != 0 and lineNumber>@tail
                                        break
                                end# no more relevant data
                        end
                end
        end # def run
        
        public
        def teardown
                @path.each do |path, cnf|
                        @gzstream[path].close
                end
                finished
        end

end # class LogStash::Inputs::Gunzip
