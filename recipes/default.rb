%w{automake libtool pkg-config liblua5.1-dev libev-dev libglib2.0-dev ragel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

directory "#{node['lighttpd2']['build_prefix']}" do
  action :create
end

bash "compile_lighttpd2" do
  cwd "#{node['lighttpd2']['build_prefix']}/lighttpd2"  
  code <<-EOF
    [ -d #{node['lighttpd2']['prefix']}/lighttpd2 ] && mv #{node['lighttpd2']['prefix']}/lighttpd2 #{node['lighttpd2']['prefix']}/lighttpd2.#{Time.to_i}
    ./autogen.sh
    ./configure --with-lua --with-openssl --prefix=#{node['lighttpd2']['prefix']}
    make
    make install
  EOF
  action :nothing
end

bash "copy_lighttpd2" do
  cwd "#{node['lighttpd2']['build_prefix']}"
  code <<-EOF
    [ -d ./lighttpd2 ] && rm -rf ./lighttpd2 ]
    cp -a #{node['lighttpd2']['src_prefix']}/lighttpd2 ./
  EOF
  action :nothing
end

git "#{node['lighttpd2']['src_prefix']}/lighttpd2" do
  repository "git://git.lighttpd.net/lighttpd/lighttpd2.git"
  reference "#{node['lighttpd2']['git_reference']}"
  action :sync
  notifies :run, "bash[copy_lighttpd2]", :immediately
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
  command "cp #{node['lighttpd2']['build_prefix']}/lighttpd2/doc/mimetypes.conf #{node['lighttpd2']['etc']}/ && chown #{node['lighttpd2']['run_as']} #{node['lighttpd2']['etc']}/mimetypes.conf"
  creates "#{node['lighttpd2']['etc']}/mimetypes.conf"
end

execute "make_fake_cert" do
  command "cat /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key > #{node['lighttpd2']['etc']}/server.pem && chown #{node['lighttpd2']['run_as']} #{node['lighttpd2']['etc']}/server.pem"
  creates "#{node['lighttpd2']['etc']}/server.pem"
end

directory "#{node['runit']['sv_dir']}/lighttpd2/log" do
  recursive true
  action :create
end

template "#{node['runit']['sv_dir']}/lighttpd2/run" do
  source "lighttpd.run.erb"
  mode 0700
end

if File.exists?("/usr/local/bin/rsvlog")
  link "#{node['runit']['sv_dir']}/lighttpd2/log/run" do
    to "/usr/local/bin/rsvlog"
  end
elsif File.exists?("/usr/bin/rsvlog")
  link "#{node['runit']['sv_dir']}/lighttpd2/log/run" do
    to "/usr/bin/rsvlog"
  end
else
  file("#{node['runit']['sv_dir']}/lighttpd2/log/run") do
    content <<-EOF
#!/usr/bin/env bash 
set -e
if [ $0 != "./run" ];then
  echo "This script meant to be linked as ./run in a service/log directory only!"
  exit 1
fi
curdir=$(basename $(pwd))
if [ "$curdir" != "log" ];then
  echo "This script meant to be run from a service/log directory only!"
  exit 1
fi
if [ -f ./conf ];then
  source ./conf
fi
if [ ! -v SV_TIMESTAMP ];then
  echo "Setting default timestamp"
  # Default to tai64 timestamps
  SV_TIMESTAMP="-t"
fi
if [ "x$SV_LOGDIR" != "x" ];then
  logdir=$SV_LOGDIR
fi
if [ -w /var/log ];then
  user_group=${USERGROUP:-daemon:adm}
  if [ "x$logdir" == "x" ];then
    logdir=$(basename $(dirname $(pwd)))
  fi
  [ -d "/var/log/$logdir" ] || mkdir -p "/var/log/$logdir"
  [ -L ./main ] || [ -d ./main ] || ln -s "/var/log/$logdir" ./main
  [ -L ./current ] || ln -s main/current
  if [ "x$CURRENT_LOG_FILE" != "x" ];then
    [ -L "/var/log/$logdir/$CURRENT_LOG_FILE" ] || ln -s current "/var/log/$logdir/$CURRENT_LOG_FILE"
  fi
  usergroup=$(stat -c "%U:%G" "/var/log/$logdir")
  if [ "$usergroup" != "$user_group" ];then
    chown -R $user_group "/var/log/$logdir"
  fi
  echo Logging as $user_group to /var/log/$logdir
  exec chpst -u $user_group svlogd ${SV_TIMESTAMP} ./main
else
  echo Logging in $PWD
  if [ "x$CURRENT_LOG_FILE" != "x" ];then
    [ -L "$CURRENT_LOG_FILE" ] || ln -s current "$CURRENT_LOG_FILE"
  fi
  exec svlogd ${SV_TIMESTAMP} ./
fi
    EOF
    mode 0750
  end
end

link "#{node['runit']['sv_dir']}/lighttpd2/supervise" do
  to "/var/run/lighttpd2.sv"
end

link "#{node['runit']['sv_dir']}/lighttpd2/log/supervise" do
  to "/var/run/lighttpd2.log.sv"
end

link "#{node['runit']['service_dir']}/lighttpd2" do
  to "#{node['runit']['sv_dir']}/lighttpd2"
end

execute "restart_lighttpd2" do
  action :nothing
  command "sv t lighttpd2"
  only_if { File.exists?("#{node['runit']['service_dir']}/lighttpd2/supervise/ok") }
end

execute "restart_lighttpd2_log" do
  action :nothing
  command "sv t #{node['runit']['service_dir']}/lighttpd2/log"
  only_if { File.exists?("#{node['runit']['service_dir']}/lighttpd2/log/supervise/ok") }
end
