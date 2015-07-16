require 'rubygems'
require 'bundler'
Bundler.require
require 'pry'

unless ARGV.length == 3
  puts 'Usage: transcript-annotator.rb "Jake Lodwick" "jake lodwick app story 1.0.xml" "jake lodwick app story 1.0.md"'
  exit(1)
end

#####################
# Config
#####################
FrameRate = 24
MaxQuoteLength = 2000

IntervieweeName = ARGV[0]
SequenceXmlPath = ARGV[1]
MarkdownPath = ARGV[2]

#####################
# Functions
#####################
containing = lambda do |method, nodes, child_node_name, search_string|
  nodes.send(method) { |seq| !seq.css(%Q[#{child_node_name}:contains("#{search_string}")]).empty? }
end
first_containing = containing.curry.(:find)
all_containing = containing.curry.(:find_all)

def format_quote_header(interviewee_name, clip)
  in_point = frames_to_formatted_timestamp(clip, 'start', FrameRate)
  out_point = frames_to_formatted_timestamp(clip, 'end', FrameRate)
  header(interviewee_name, in_point, out_point)
end

def frames_to_formatted_timestamp(clip, node_name, frame_rate)
  remove_leading_zeroes_from_timestamp(seconds_to_timestamp(clip.css(node_name).text.to_i / frame_rate))
end

def header(name, in_point='', out_point='')
  "#{name} (#{in_point}-#{out_point})"
end

def highlighted_quotes(html, highlight_tag='strong')
  Nokogiri::HTML(html).
    css(highlight_tag).
    map(&:text)
end

def markdown_path_to_html(markdown_path)
  GitHub::Markup.render(markdown_path, File.read(markdown_path))
end

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

def split_long_quotes(text, char_limit)
  return text if text.length <= char_limit
  excerpt, leftover = truncate_on_word_boundary(text, char_limit)
  [excerpt, split_long_quotes(leftover, char_limit)].
    flatten.
    join("\n***[BREAK]***\n")
end

def truncate_on_word_boundary(text, char_limit)
  return text if text.length <= char_limit

  index_of_last_whitespace_within_char_limit = text[0..char_limit].
    index(/ [^ ]*$/)
  excerpt = text[0...index_of_last_whitespace_within_char_limit]
  remainder = text[(index_of_last_whitespace_within_char_limit+1)..-1]
  return [excerpt, remainder]
end

def zip_quote_headers_and_bodies(headers, bodies)
  if headers.length < bodies.length
    off_by = bodies.length - headers.length
    off_by.times { headers.push(header(IntervieweeName)) }
  end
  headers.
    zip(bodies).
    map { |pair| pair.join(' ') }
end

#####################
# Implementation
#####################
project = Nokogiri::XML(File.read(SequenceXmlPath))

sequence = project.css('sequence')

golden_clips = all_containing.(sequence.css('media video track').first.css('clipitem'),
                               'labels label2',
                               'Mango')

quote_headers = golden_clips.map { |gc| format_quote_header(IntervieweeName, gc) }
quote_bodies = highlighted_quotes(markdown_path_to_html(MarkdownPath))

if quote_headers.length != quote_bodies.length
  puts "~> Woops. We don't have the same number of marked clips and marked quotes."
  puts "~> The output will need some massaging to resolve this."
  puts "     Clips: #{quote_headers.length}"
  puts "    Quotes: #{quote_bodies.length}"
  puts "================================================================\n\n"
end

zipped = zip_quote_headers_and_bodies(quote_headers, quote_bodies)
puts zipped.
  map { |quote| split_long_quotes(quote, MaxQuoteLength) }.
  join("\n\n\n\n================================================================\n\n\n\n")
