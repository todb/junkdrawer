#!/usr/bin/env ruby

require 'webrick'
require 'stringio'
include WEBrick
port = ENV['HTTP_PORT'] || 8080
s = HTTPServer.new(:Port => port, :DocumentRoot => Dir.pwd)

s.mount_proc '/upload' do |request, response|
  request.query.collect do |k,v|
    if k == "filename"
      @fname = "#{Time.now.to_f}-#{v}".strip
    end
    if k == "filedata"
      @fsize = File.open(File.join(Dir.pwd, "#{@fname}"), "wb") {|f| f.write v}
    end
  end
  response.body = "<html>Got #{@fname} #{@fsize} bytes <a href='up'>do it again</a></html>"
end

s.mount_proc '/up' do |request, response|
  response.body =<<EOF
<html>
  <form action="upload" method="POST" enctype="multipart/form-data">
    Filename: <input name="filename" type="text"/>
    <br />
    File: <input type="file" name="filedata" />
    <br />
    <input type="submit" value="Upload" />
  </form>
</html>
EOF
end

trap("INT") { s.shutdown }
s.start
