#!/usr/bin/env ruby

require 'webrick'
require 'stringio'
include WEBrick
port = ENV['HTTP_PORT'] || 8080
dir  = ENV['HTTP_DIR']  || Dir.pwd
s = HTTPServer.new(:Port => port, :DocumentRoot => dir)

s.mount_proc '/upload' do |request, response|
  request.query.collect do |k,v|
    if k == "filename"
      @fname = "#{Time.now.to_f}-#{v}".strip
      @fname = File.join(dir,@fname)
    end
    if k == "filedata"
      @fsize = File.open(@fname, "wb") {|f| f.write v}
    end
  end
  msg = "Got #{@fname} (#{@fsize} bytes)"
  response.body = "<html>#{msg}<br><a href='up'>do it again</a></html>"

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
