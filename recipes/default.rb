%w{automake libtool pkg-config liblua5.1-dev libev-dev libglib2.0-dev ragel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

directory "/usr/local/build" do
  action :create
end

bash "compile_lighttpd2" do
  cwd "/usr/local/build/lighttpd2"  
  code <<-EOF
    ./autogen.sh
    ./configure --with-lua --with-openssl --prefix=#{node['lighttpd2']['prefix']}
    make
    make install
  EOF
  action :nothing
end

bash "clone_lighttpd2" do
  cwd "/usr/local/build"
  code <<-EOF
    [ -d ./lighttpd2 ] && rm -rf ./lighttpd2
    git clone /usr/local/src/lighttpd2
  EOF
  action :nothing
end

git "/usr/local/src/lighttpd2" do
  repository "git://git.lighttpd.net/lighttpd/lighttpd2.git"
  reference "master"
  action :sync
  notifies :run, "bash[clone_lighttpd2]", :immediately
  notifies :run, "bash[compile_lighttpd2]", :immediately
end

directory node['lighttpd2']['etc'] do
  action :create
  owner node['lighttpd2']['run_as']
  recursive true
end

directory node['lighttpd2']['conf_dir'] do
  action :create
  recursive true
  owner node['lighttpd2']['run_as']
end

template "#{node['lighttpd2']['etc']}/lighttpd.conf" do
  source "lighttpd.conf.erb"
  owner node['lighttpd2']['run_as']
end

template "#{node['lighttpd2']['etc']}/angel.conf" do
  source "angel.conf.erb"
end

execute "copy_mimetypes" do
  command "cp /usr/local/build/lighttpd2/doc/mimetypes.conf #{node['lighttpd2']['etc']}/ && chown #{node['lighttpd2']['run_as']} #{node['lighttpd2']['etc']}/mimetypes.conf"
  creates "#{node['lighttpd2']['etc']}/mimetypes.conf"
end

execute "make_fake_cert" do
  command "cat /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key > #{node['lighttpd2']['etc']}/server.pem && chown #{node['lighttpd2']['run_as']} #{node['lighttpd2']['etc']}/server.pem"
  creates "#{node['lighttpd2']['etc']}/server.pem"
end

directory "/etc/sv/lighttpd2/log" do
  recursive true
  action :create
end

template "/etc/sv/lighttpd2/run" do
  source "lighttpd.run.erb"
  mode 0700
end

link "/etc/sv/lighttpd2/log/run" do
  to "/usr/local/bin/rsvlog"
end

link "/etc/sv/lighttpd2/supervise" do
  to "/var/run/lighttpd2.sv"
end

link "/etc/sv/lighttpd2/log/supervise" do
  to "/var/run/lighttpd2.log.sv"
end

link "/etc/service/lighttpd2" do
  to "/etc/sv/lighttpd2"
end

execute "restart_lighttpd2" do
  action :nothing
  command "sv t lighttpd2"
  only_if { File.exists?("/etc/sv/lighttpd2/supervise/ok") }
end
