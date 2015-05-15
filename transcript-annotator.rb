require 'rubygems'
require 'bundler'
Bundler.require
require 'pry'

FrameRate = 24

# Usage: transcript-annotator.rb "Jake Lodwick" "jake lodwick app story 1.0.xml" 

def remove_leading_zeroes_from_timestamp(timestamp)
  [/^00:0/,
   /^00:/,
   /^0/].each do |r|
     return timestamp.sub(r, '') if r.match(timestamp)
   end
end

def seconds_to_timestamp(seconds)
  Time.at(seconds).utc.strftime('%H:%M:%S')
end

containing = lambda do |method, nodes, child_node_name, search_string|
  nodes.send(method) { |seq| !seq.css(%Q[#{child_node_name}:contains("#{search_string}")]).empty? }
end
first_containing = containing.curry.(:find)
all_containing = containing.curry.(:find_all)

project = Nokogiri::XML(File.read(ARGV[1]))

sequence = project.css('sequence')

golden_clips = all_containing.(sequence.css('media video track').first.css('clipitem'),
                               'labels label2',
                               'Mango')

def frames_to_formatted_timestamp(clip, node_name, frame_rate)
  remove_leading_zeroes_from_timestamp(seconds_to_timestamp(clip.css(node_name).text.to_i / frame_rate))
end

golden_clips.each do |clip|
  in_point = frames_to_formatted_timestamp(clip, 'start', FrameRate)
  out_point = frames_to_formatted_timestamp(clip, 'end', FrameRate)
  puts "**#{ARGV[0]}** (#{in_point}-#{out_point})"
end
