#!/bin/sh

echo "请输入验证码密码:"
read -s captcha

if [ "$captcha" != "789" ]; then
    echo "验证码密码错误！"
    exit 1
fi

echo "请输入socks端口:"
read socks_port
echo "请输入socks用户名:"
read socks_user
echo "请输入socks密码:"
read socks_pass

# 以下是原始代码，没有进行修改
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables-save
ips=(
$(hostname -I)
)
# Xray Installation
wget -O /usr/local/bin/xray https://raw.githubusercontent.com/llccool1/llccools4s5/main/xray
chmod +x /usr/local/bin/xray
cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=The Xray Proxy Serve
After=network-online.target

[Service]
ExecStart=/usr/local/bin/xray -c /etc/xray/serve.toml
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=15s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable xray

# Xray Configuration
mkdir -p /etc/xray
echo -n "" > /etc/xray/serve.toml
for ((i = 0; i < ${#ips[@]}; i++)); do
    cat <<EOF >> /etc/xray/serve.toml
[[inbounds]]
listen = "${ips[i]}"
port = $socks_port
protocol = "socks"
tag = "$((i+1))"

[inbounds.settings]
auth = "password"
udp = true
ip = "${ips[i]}"

[[inbounds.settings.accounts]]
user = "$socks_user"
pass = "$socks_pass"

[[routing.rules]]
type = "field"
inboundTag = "$((i+1))"
outboundTag = "$((i+1))"

[[outbounds]]
sendThrough = "${ips[i]}"
protocol = "freedom"
tag = "$((i+1))"
EOF
done

# 设置防火墙
firewall-cmd --zone=public --add-port=$socks_port/tcp --add-port=$socks_port/udp --permanent && firewall-cmd --reload

systemctl stop xray
systemctl start xray

# 显示本机所有IP地址
filename=$(hostname -I | awk '{print $1}').txt
echo "$(date '+%Y-%m-%d')" > $filename
hostname -I | tr ' ' '\n' >> $filename 

# 重启xray
systemctl restart xray

# 删除安装脚本
cleanup() {
  rm -f /root/socks51.sh
}
trap cleanup EXIT

# 显示完成信息
echo "====================================="
echo "  "
echo "==>已安装完毕，赶紧去测试一下!  "
echo "  "
echo "==>如有问题请加TG:@Ammkiss     "
echo "  "
echo "==>服务器购买：irqm.com     "
echo "  "
echo "====================================="
