maintainer        "TJ Vanderpoel"
maintainer_email  "tj@rubyists.com"
license           "MIT"
description       "Installs and configures lighttpd2"
version           "2.0.0"

recipe "lighttpd2", "Installs lighttpd from source in /opt and sets up configuration with Debian apache style with sites-enabled/sites-available"
recipe "lighttpd2_vhost", "Sets up a vhost for serving through lighttpd (proxy or fastcgi)"

%w{ ubuntu debian }.each do |os|
  supports os
end

%w{ build-essential runit }.each do |cb|
  depends cb
end

attribute "lighttpd2/dir",
  :display_name => "lighttpd2 Directory",
  :description => "Location of lighttpd2 configuration files",
  :default => "/opt/lighttpd2/etc"

attribute "lighttpd2/log_dir",
  :display_name => "Lighttpd2 Log Directory",
  :description => "Location for lighttpd2 logs",
  :default => "/var/log/lighttpd2"

attribute "lighttpd2/user",
  :display_name => "Lighttpd2 User",
  :description => "User lighttpd2 will run as",
  :default => "www-data"

attribute "lighttpd2/binary",
  :display_name => "Lighttpd2 Binary",
  :description => "Location of the lighttpd2 server binary",
  :default => "/opt/lighttpd2/sbin/lighttpd2"

attribute "lighttpd2/keepalive",
  :display_name => "Lighttpd2 Keepalive",
  :description => "Whether to enable keepalive",
  :default => "on"

attribute "lighttpd2/keepalive_timeout",
  :display_name => "Lighttpd2 Keepalive Timeout",
  :default => "65"

attribute "lighttpd2/worker_processes",
  :display_name => "Lighttpd2 Worker Processes",
  :description => "Number of worker processes",
  :default => "1"

attribute "lighttpd2/worker_connections",
  :display_name => "Lighttpd2 Worker Connections",
  :description => "Number of connections per worker",
  :default => "1024"

