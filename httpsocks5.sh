#!/bin/bash
function install_http() {
  yum install -y openssl
  yum install -y squid
  yum install -y net-tools
  cat <<EOF >/etc/squid/squid.conf

# Recommended minimum configuration:

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# Recommended minimum Access Permission configuration:

# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
http_access allow localnet
http_access allow localhost

acl client src 0.0.0.0/0
http_access allow client

request_header_access X-Forwarded-For deny all
request_header_access From deny all
request_header_access Via deny all

# And finally deny all other access to this proxy
http_access deny all

# Squid normally listens to port 3128
http_port 32122

# Uncomment and adjust the following to add a disk cache directory.
# cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

# Add any of your own refresh_pattern entries above these.

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
EOF
  systemctl start squid            #开启squid
  systemctl restart squid          #开启squid
  systemctl enable squid.service   #设置开机自动启动
}
function install_socks5() {
  wget --no-check-certificate https://raw.github.com/512577639/CentOS7/main/socks5.sh -O socks5.sh.sh
  bash socks5.sh --port=32123 --user=8888 --passwd=8888
}
function open_port() {
  PORT=32123
  # 检查firewalld服务是否正在运行
  if ! systemctl is-active --quiet firewalld; then  
      echo "Firewalld 服务未运行，正在尝试启动..."
      sudo systemctl start firewalld
      if ! systemctl is-active --quiet firewalld; then
          echo "无法启动firewalld服务，请手动检查并启动它。"
          exit 1
      fi
      echo "Firewalld 服务已启动。"
  fi
  # 永久开放端口
  echo "正在永久开放 $PORT 端口..."
  sudo firewall-cmd --zone=public --add-port=$PORT/tcp --permanent
  
  # 重新加载firewalld规则以应用更改
  echo "重新加载firewalld规则..."
  sudo firewall-cmd --reload
  
  # 验证端口是否已开放
  if sudo firewall-cmd --zone=public --list-ports | grep -q "$PORT/tcp"; then
      echo "$PORT 端口已成功开放。"
  else
      echo "开放端口失败，请检查错误。"
      exit 1
  fi
}
yum install -y wget
install_http
install_socks5
systemctl stop firewalld.service
systemctl disable firewalld.service
