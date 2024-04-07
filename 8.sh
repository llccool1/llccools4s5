#!/bin/sh

echo "请输入验证码密码:"
read -s captcha

if [ "$captcha" != "789" ]; then
    echo "验证码密码错误！"
    exit 1
fi

echo "请输入socks用户名:"
read socks_user
echo "请输入socks密码:"
read socks_pass

# 清空防火墙规则
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables-save

# 获取本机所有IP地址
ips=($(hostname -I))

# Xray 安装
wget -O /usr/local/bin/xray https://raw.githubusercontent.com/llccool1/llccools4s5/main/xray
chmod +x /usr/local/bin/xray

# 创建 Xray 服务配置文件
mkdir -p /etc/xray
echo -n "" > /etc/xray/serve.toml

# 创建信息文本文件
filename=$(hostname -I | awk '{print $1}').txt
echo "$(date '+%Y-%m-%d')" > $filename

# 循环为每个IP分配端口并配置Xray
for ((i = 0; i < ${#ips[@]}; i++)); do
    current_port=$((5000 + i))

    # 追加配置到 serve.toml 文件
    cat <<EOF >> /etc/xray/serve.toml
[[inbounds]]
listen = "${ips[i]}"
port = $current_port
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

    # 追加信息到文本文件
    echo "${ips[i]}:$current_port:$socks_user:$socks_pass" >> "$filename"
done

# 关闭端口
for ((p = 5000; p <= current_port; p++)); do
    firewall-cmd --zone=public --remove-port=$p/{tcp,udp} --permanent
done
firewall-cmd --reload

# 设置防火墙规则
firewall-cmd --zone=public --add-port=5000-$(($current_port))/{tcp,udp} --permanent && firewall-cmd --reload

# 配置Xray服务
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

# 启动Xray服务
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# 删除安装脚本
cleanup() {
  rm -f /root/xray_setup.sh
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
