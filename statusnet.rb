#
# $Id$
#
# $Revision$
#

require 'net/https'
require 'open-uri'
require 'json'

module Msf
	class Plugin::Statusnet < Msf::Plugin
		include Msf::SessionEvent
		
		class StatusnetCommandDispatcher
			include Msf::Ui::Console::CommandDispatcher
			
			attr_accessor :username, :password, :uri, :port, :ssl
			attr_accessor :update, :friends

			def name
				"StatusNet"
			end

			def commands
				{
					"sn_connect"    => "Connect: statusnet_connect <user:pass>[@uri[:port]] [ssl]",
					"sn_post"       => "Post status (freeform)",
					"sn_disconnect" => "Disconnect from StatusNet",
					"sn_info"       => "Display StatusNet credential info"
				}
			end
			
			def sn_usage
				print_status("Usage:")
				commands.each_pair {|k,v| print_line "%20s : %s",[k,v]}
			end			
			
			def cmd_sn_connect(*args)
				connection_regex = /([^:]+):([^@]+)@(.+)/
				args[0][connection_regex]
				self.username = $1
				self.password = $2
				self.uri = $3
				self.ssl = (!!args[1])
				if username && password && uri
					print_status "Connecting as #{username}:#{password} to #{uri} (SSL: #{ssl})"
				else
					print_error "The format for arguments is 'user:pass@uri:post [ssl]'"
					return nil
				end
				if _find_api()
					_test_connection()
				end
			end

			def _test_connection()
				uri = URI.parse(self.friends.gsub(/xml$/,"json"))
				res = nil
				unless uri
					print_error "Some kind of horrible error during connection."
					return false
				end
				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = (uri.scheme == "https")
				http.start do |h|
					req = Net::HTTP::Get.new(uri.request_uri)
					req.basic_auth(self.username, self.password)
					response = http.request(req)
					res = JSON.parse response.body
				end
				if res.kind_of? Array
					print_good "Successful authentication to StatusNet server #{uri.host}"
					return true
				elsif res.kind_of?(Hash) && res["error"]
					print_error res["error"]
				else
					print_error "Unknown error when connectiong to #{uri.host}"
				end
				return false
			end

			# It'd be nicer to parse this sensibly with an XML lexer but whatever for now.
			def _find_api()
				rsd_link = nil
				api_link = nil
				open("http://#{self.uri}") do |f|
					f.each_line do |line| 
						next unless line =~ /EditURI/
						next unless line =~ /"application\/rsd\+xml"/
						next unless line =~ /<link.*href=\s*[\x22\x27]([^\x22\x27]*)[\x22\x27]/
						rsd_link = $1
						break if rsd_link
					end
				end
				unless rsd_link
					print_error "Could not find the RSD link at http://#{uri}"
					return nil
				end
				open(rsd_link) do |f|
					f.each_line do |line|
						next unless line =~ /apiLink/
						next unless line =~ /Twitter/
						next unless line =~ /apiLink\s*=\s*[\x22\x27]([^\x22\x27]*)[\x22\x27]/
						api_link = $1
						break if api_link
					end
				end
				unless api_link
					print_error "Could not find the API link at http://#{uri}"
					return nil
				end
				self.update	= api_link + "statuses/update.xml"
				self.friends = api_link + "statuses/friends_timeline.xml"
				return true
			end
			
			def cmd_sn_post(*args)
				return nil unless args
				unless self.update
					print_error "Not connected yet! Try sn_connect first."
					return false
				end
				msg = args.join(" ")
				uri = URI.parse(self.update.gsub(/xml$/,"json"))
				res = nil
				unless uri
					print_error "Some kind of horrible error during connection."
					return false
				end
				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = (uri.scheme == "https")
				http.start do |h|
					req = Net::HTTP::Post.new(uri.request_uri)
					req.basic_auth(self.username, self.password)
					req.set_form_data({
						'status' => msg,
						'source' => "Metasploit"
					})
					response = http.request(req)
					res = JSON.parse response.body
				end
				if res["error"]
					print_error "Error: #{res["error"]}"
				else
					print_status "Status posted." 
				end
			end
			
			def cmd_sn_disconnect()
				self.update = nil
				self.friends = nil
			end
			
			def cmd_sn_info()
				if self.update
					print_status "StatusNet connection info:"
					print_line "  Username: #{self.username}"
					print_line "  URI:      #{self.uri}"
					print_line "  Password: #{self.password}"
					print_line "  SSL:      #{self.ssl}"
				else
					print_status "Not logged in to any StatusNet service."
				end
			end
			
		end
		
		def on_session_open(session)
			this_driver = opts['ConsoleDriver'].dispatcher_stack.select {|dr| dr.kind_of? StatusnetCommandDispatcher}.first
			return nil unless this_driver.update
			# These values have already been validated to work by sn_connect
			connect_array = [this_driver.username, this_driver.password, this_driver.update, this_driver.ssl || false]
			report_session_to_statusnet({
				:user => this_driver.username,
				:pass => this_driver.password,
				:uri => this_driver.update,
				:ssl => this_driver.ssl,
				:session => session}
			)
		end
		
		def on_session_close(session, reason="")
			
		end
		
		def report_session_to_statusnet(args={})
			print_status "StatusNet: Reporting..."
			user     = args[:user]
			pass     = args[:pass]
			update   = args[:uri]
			ssl      = args[:ssl]
			session  = args[:session]
			return nil unless [user,pass,update].compact.size == 3
			msg = format_message_for_statusnet(session)
			begin
				uri = URI.parse(update.gsub(/xml$/,"json"))
				res = nil
				unless uri
					print_error "StatusNet: Some kind of horrible error. Sorry it didn't work out." 
					return false
				end
				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = (uri.scheme == "https")
				http.start do |h|
					req = Net::HTTP::Post.new(uri.request_uri)
					req.basic_auth(user,pass)
					req.set_form_data({
						'status' => msg,
						'source' => "Metasploit"
					})
					response = http.request(req)
					res = JSON.parse response.body
				end
				if res["error"]
					print_error "StatusNet Error: #{res["error"]}"
				else
					print_good "StatusNet: Session record posted: @#{user}: '#{msg}'." 
				end
			rescue
				print_error "Caught error #{$!.class}, so couldn't report to StatusNet. Moving on..."
			end
		end

		def format_message_for_statusnet(session)
			msg = []
			msg << "#{session.type.to_s.capitalize} session opened on #{session.target_host}"
			if session.exploit && session.exploit.respond_to?(:refname)
				msg << "using #{session.exploit.refname}"
			end
			unless session.exploit_datastore['Payload'].to_s.empty?
				msg << "with #{session.exploit_datastore['Payload'].to_s}"
			end
			if (status = msg.join(", ")).size > 140
				status = msg[0,2].join(", ")
			end
			return status
		end
			
		def initialize(framework, opts)
			super
			self.framework.events.add_session_subscriber(self)
			add_console_dispatcher(StatusnetCommandDispatcher)
		end
			
		def cleanup
			self.framework.events.remove_session_subscriber(self)
			remove_console_dispatcher('StatusNet')
		end
					
		def name
			"statusnet"
		end
		
		def desc
			"Automatically broadcast successful exploits to a public or private StatusNet microblog"
		end
			
	end
end
