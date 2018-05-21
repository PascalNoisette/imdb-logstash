# imdb-logstash

Configuration and plugins to parse imdb data dump.

Requirements :
Logstash 1.5 http://logstash.net/

Input files : 
http://www.imdb.com/interfaces

Usage :
bin/logstash-plugin install logstash-input-gunzip
bin/logstash-plugin install logstash-filter-multiline
bin/logstash agent -f config