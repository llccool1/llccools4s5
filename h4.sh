#!/bin/sh

echo "请输入验证码密码:"
read -s captcha

if [ "$captcha" != "789" ]; then
    echo "验证码密码错误！"
    exit 1
fi

echo "请输入 SOCKS5 代理端口:"
read socks5_port
echo "请输入 HTTP 代理端口:"
read http_port
echo "请输入代理用户名:"
read proxy_user
echo "请输入代理密码:"
read proxy_pass

# 清除旧的防火墙规则
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables-save

ips=($(hostname -I))

# 下载和安装 Xray
wget -O /usr/local/bin/xray https://raw.githubusercontent.com/llccool1/llccools4s5/main/xray
chmod +x /usr/local/bin/xray

# 创建 Xray 服务配置
cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=The Xray Proxy Server
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

# 配置 Xray
mkdir -p /etc/xray
echo -n "" > /etc/xray/serve.toml

for ((i = 0; i < ${#ips[@]}; i++)); do
    cat <<EOF >> /etc/xray/serve.toml
[[inbounds]]
listen = "${ips[i]}"
port = $socks5_port
protocol = "socks"
tag = "socks-$((i+1))"

[inbounds.settings]
auth = "password"
udp = true
ip = "${ips[i]}"

[[inbounds.settings.accounts]]
user = "$proxy_user"
pass = "$proxy_pass"

[[routing.rules]]
type = "field"
inboundTag = "socks-$((i+1))"
outboundTag = "socks-$((i+1))"

[[outbounds]]
sendThrough = "${ips[i]}"
protocol = "freedom"
tag = "socks-$((i+1))"
EOF

    cat <<EOF >> /etc/xray/serve.toml
[[inbounds]]
listen = "${ips[i]}"
port = $http_port
protocol = "http"
tag = "http-$((i+1))"

[inbounds.settings]
auth = "password"
udp = true
ip = "${ips[i]}"

[[inbounds.settings.accounts]]
user = "$proxy_user"
pass = "$proxy_pass"

[[routing.rules]]
type = "field"
inboundTag = "http-$((i+1))"
outboundTag = "http-$((i+1))"

[[outbounds]]
sendThrough = "${ips[i]}"
protocol = "freedom"
tag = "http-$((i+1))"
EOF

done

# 设置防火墙规则
firewall-cmd --zone=public --add-port=$socks5_port/tcp --add-port=$socks5_port/udp --add-port=$http_port/tcp --add-port=$http_port/udp --permanent && firewall-cmd --reload

# 重启 Xray 服务
systemctl stop xray
systemctl start xray

# 显示本机所有IP地址
filename=$(hostname -I | awk '{print $1}').txt
echo "$(date '+%Y-%m-%d')" > $filename
hostname -I | tr ' ' '\n' >> $filename

# 重启 xray
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
