#!/usr/bin/env ruby

require 'json'
require 'base64'
require 'optparse'
require 'shellwords'
require 'open3'

module Extractor
  class << self
    def extract(file_path)
      metadata = read_tags(file_path)
      save_metadata(metadata)
      puts "Metadata extracted and saved to metadata.json"
    rescue StandardError => e
      puts "Error extracting metadata: #{e.message}"
    end

    private

    def read_tags(file_path)
      escaped_path = Shellwords.escape(file_path)
      stdout, stderr, status = Open3.capture3("ffprobe -v quiet -print_format json -show_format #{escaped_path}")

      raise "Failed to read file: #{stderr}" unless status.success?

      data = JSON.parse(stdout)
      tags = data['format']['tags'] || {}

      {
        title: tags['title'] || 'Unknown Title',
        artist: tags['artist'] || 'Unknown Artist',
        album: tags['album'] || 'Unknown Album',
        album_art: extract_album_art(file_path)
      }
    end

    def extract_album_art(file_path)
      escaped_path = Shellwords.escape(file_path)
      stdout, stderr, status = Open3.capture3("ffprobe -v quiet -select_streams v -count_packets -show_entries stream=codec_type:stream_tags -of json #{escaped_path}")

      return nil unless status.success?

      data = JSON.parse(stdout)
      album_art_stream = data['streams']&.find { |stream| stream['codec_type'] == 'video' }
      return nil unless album_art_stream

      mime_type = album_art_stream['tags']['mime_type'] || 'image/jpeg'

      stdout, stderr, status = Open3.capture3("ffmpeg -i #{escaped_path} -an -vcodec copy -f rawvideo -")
      return nil unless status.success?

      {
        mime_type: mime_type,
        data: Base64.strict_encode64(stdout)
      }
    end

    def save_metadata(metadata)
      File.write('metadata.json', JSON.pretty_generate(metadata))
    end
  end
end

# CLI handling
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} <path_to_mp3_file>"

  opts.on("-h", "--help", "There is no one around to help") do
    puts opts
    exit
  end
end.parse!(into: options)

if ARGV.empty?
  puts "Please provide the path to the MP3 file as an argument."
  exit(1)
end

Extractor.extract(ARGV[0])
