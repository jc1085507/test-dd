#!/usr/bin/env bash

set -e
exec 2>&1

UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
WSPATH=${WSPATH:-'argo'}

generate_config() {
  cat > /tmp/config.json << EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "route": {
    "geoip": {
      "path": "/tmp/geoip.db",
      "download_url": "https://fastly.jsdelivr.net/gh/soffchen/sing-geoip@release/geoip.db",
      "download_detour": "direct"
    },
    "geosite": {
      "path": "/tmp/geosite.db",
      "download_url": "https://fastly.jsdelivr.net/gh/soffchen/sing-geosite@release/geosite.db",
      "download_detour": "direct"
    },
    "rules": [
      {
        "geosite": ["openai"],
        "outbound": "warp-IPv4-out"
      }
    ]
  },
  "inbounds": [
    {
      "sniff": true,
      "sniff_override_destination": true,
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": 63003,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/${WSPATH}/vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "direct",
      "tag": "warp-IPv4-out",
      "detour": "wireguard-out",
      "domain_strategy": "ipv4_only"
    },
    {
      "type": "direct",
      "tag": "warp-IPv6-out",
      "detour": "wireguard-out",
      "domain_strategy": "ipv6_only"
    },
    {
      "type": "wireguard",
      "tag": "wireguard-out",
      "server": "162.159.192.1",
      "server_port": 2408,
      "local_address": [
        "172.16.0.2/32",
        "2606:4700:110:8741:94a0:ed11:528e:15ce/128"
      ],
      "private_key": "mBLyQdleKfbd+DyY5qfAH+35khgKVQSL6V9agcxVIWI=",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [217, 40, 145],
      "mtu": 1280
    }
  ]
}
EOF
}

generate_pm2_file() {
  cat > /tmp/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: "web",
      script: "/usr/src/app/app* run -c /tmp/config.json"
    }
  ]
}
EOF
}


generate_config
generate_pm2_file

[ -e /tmp/ecosystem.config.js ] && pm2 start /tmp/ecosystem.config.js