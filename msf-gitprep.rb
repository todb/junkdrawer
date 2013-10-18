#!/usr/bin/ruby


# The goal here is to set sensible aliases and fetch patterns for things
# that Metasploit developers like to do.

# Local:
=begin

[alias]
  pr-url =!"xdg-open https://github.com/todb-r7/metasploit-model/pull/new/$1:$2...$(git branch-current) #"
[remote "origin"]
  fetch = +refs/heads/*:refs/remotes/origin/*
  url = github-r7:todb-r7/metasploit-model
  fetch = +refs/pull/*/head:refs/remotes/origin/pr/*
[remote "upstream"]
  url = github-r7:rapid7/metasploit-model
  fetch = +refs/heads/*:refs/remotes/upstream/*
  fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*
[branch "upstream-master"]
  remote = upstream
  merge = refs/heads/master

=end

class GitInfo
  attr_reader :origin_url, :repo, :uri_handler

  def initialize
    set_origin
    set_repo
    set_uri_handler
  end

  def remote_v
    @remote_v ||= %x{git remote -v}
  end

  def set_origin
    remote_v =~ /^origin(.*)\(push\)$/
    @origin_url = $1.strip
  end

  def set_repo
    @repo = @origin_url.split("/").last
  end

  def set_uri_handler
    if @origin_url.start_with? "https://"
      @uri_handler = "https://github.com/"
    else
      @uri = @origin_url.split(":").first
      @uri << ":"
    end
  end

  def add_upstream
    return if @remote_v =~ /upstream\s.*github\.com\/rapid7\/#{@repo}/
    puts "Adding upstream repo."
    %x{git remote add upstream #{@uri}rapid7/#{@repo}}
  end

end

def go
  g = GitInfo.new
  g.add_upstream
end

go

