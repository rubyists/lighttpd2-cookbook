default['lighttpd2']['src_prefix'] = '/usr/local/src' # Where to download the sources (+ /lighttpd2)
default['lighttpd2']['build_prefix'] = '/usr/local/build' # Where to build the sources (+ /lighttpd2)
default['lighttpd2']['prefix'] = '/opt/lighttpd2' # Install prefix
default['lighttpd2']['etc'] = '/opt/lighttpd2/etc' # Etc directory
default['lighttpd2']['conf_dir'] = '/opt/lighttpd2/etc/conf.d' # Where additional configuration files go
default['lighttpd2']['listen_addresses'] = ['0.0.0.0:80']
default['lighttpd2']['openssl']['enable'] = true
default['lighttpd2']['openssl']['hosts'] = [
  {
    :listen => '0.0.0.0:443',
    :pemfile => '/opt/lighttpd2/etc/server.pem'
  }
]
default['lighttpd2']['modules'] = [:accesslog, :openssl, :lua, :proxy, :balance, :expire, :vhost, :redirect]
default['lighttpd2']['index_files'] = %w{index.html index.html}
default['lighttpd2']['applications'] = []
default['lighttpd2']['run_as'] = "www-data"
default['lighttpd2']['git_reference'] = "master"
default['lighttpd2']['ssl_redirect'] = false
