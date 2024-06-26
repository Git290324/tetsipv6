#!/bin/sh

random() {
  tr </dev/urandom -dc A-Za-z0-9 | head -c5
  echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

gen64() {
  ip64() {
    echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
  }
  echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
  echo "Installing 3proxy..."
  
  URL="https://github.com/z3APA3A/3proxy/archive/3proxy-0.8.6.tar.gz"
  
  wget -qO- $URL | bsdtar -xvf-
  
  cd 3proxy-3proxy-0.8.6
  make -f Makefile.Linux
  
  mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
  
  cp src/3proxy /usr/local/etc/3proxy/bin/
  
  cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
  chmod +x /etc/init.d/3proxy
  
  chkconfig 3proxy on
  
}

# Các hàm khác như gen_3proxy, gen_proxy_file_for_user, upload_proxy, install_jq, upload_2file, gen_data, gen_iptables, gen_ifconfig được giữ nguyên từ mã script gốc.

echo "Installing apps..."
yum -y install gcc net-tools bsdtar zip >/dev/null

install_3proxy

echo "Working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal IP = ${IP4}. External sub for IP6 = ${IP6}"

echo "How many proxies do you want to create? Example: 500"
read COUNT

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT))

gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF

bash /etc/rc.local

gen_proxy_file_for_user

# upload_proxy

install_jq && upload_2file
