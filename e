#!/bin/bash
# ============================================
#  Easy 管理面板  v1.4
#  纯本地 bash · 零下载 · 零第三方
#  启动:       e
#  源码审查:   cat /usr/local/bin/e
#  卸载:       rm -f /usr/local/bin/e
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
NC='\033[0m'

# 统一 y/n 确认 (红色 [!] 高亮前缀)
# 用法: if confirm "要做的事"; then ...; fi
confirm() {
  local ans
  echo -en "  ${RED}[!]${NC} $1 ${YELLOW}(y/n):${NC} "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

# 需要 root 权限 (ufw/apt/sed 系统文件均需 root)
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}  请以 root 运行: sudo bash $0${NC}"
  exit 1
fi

# 脚本路径跟踪 (改快捷键后更新)
SCRIPT_PATH=$(readlink -f "$0")

# 初始主机名 (首次运行时自动记录，用于"恢复默认")
ORIG_HOSTNAME=""

# ---------- 封面 ----------
cover() {
  clear
  printf '\033[1;34m'
  cat <<'COVER'
▄▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄      ▄▄▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄   ▄▄▄▄▄
█          █ █       ▀▀▄   █           █ █   █   █   █
    █▀▀▀▀▀▀▀     ▄▄▄    ▀▄     █▀▀▀▀▀▀▀▀     █   █   █
▀   ▀▀▀▀▀▀▀▀ ▀   █  ▀▄   ▀ ▀   ▀▀▀▀▀▀▀▀▄ ▀   ▀▀▀▀▀   ▀
█ ░ ▄▄▄▄▄▄▄█ █ ░ █▄▄▄▀   █ ▀▄▄▄▄▄▄▄▄ ░ █  ▀▄▄▄▄▄▄▄ ░ █
█ ▒ ▀▄       █ ▒         █ ▄▄▄▄▄   █ ▒ █        ▄▀▄▒ █
█ ▀▓▓▄▀▀▄▄▄▄ █ ▓ █▀▀▀█   █ █   █▄▄▄█ ▓ █ █▀▀▀▀▀▀▄▓▓ █ 
█    ▀▀▀   █ █ ▀ █   █   █ █ ▀       ▀ █ █ ▀ ▀▀▀▀▄▄▀  
▀▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀   ▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀
COVER
  printf '\033[1;36m'
  echo "                  E a s y 管 理 面 板  v1.4"
  printf '\033[0m'
  echo ""
}

# ---------- 菜单 ----------
menu() {
  cover
  echo ""
  echo "  ──────────────────────────────────────────────"
  echo -e "   ${GREEN}1${NC}) 系统状态       ${GREEN}11${NC}) SOCKS5"
  echo -e "   ${GREEN}2${NC}) 网络状态       ${GREEN}12${NC}) Ping 测试"
  echo -e "   ${GREEN}3${NC}) 系统日志       ${GREEN}13${NC}) 记事本"
  echo -e "   ${GREEN}4${NC}) 清理垃圾"
  echo -e "   ${GREEN}5${NC}) 系统工具"
  echo -e "   ${GREEN}6${NC}) 端口状态"
  echo -e "   ${GREEN}7${NC}) 防火墙管理"
  echo -e "   ${GREEN}8${NC}) 文件管理"
  echo -e "   ${GREEN}9${NC}) 软件管理"
  echo -e "  ${GREEN}10${NC}) BBR 加速"
  echo ""
  echo -e "               ${GREEN}0${NC}) 退出"
  echo "  ──────────────────────────────────────────────"
  echo ""
  read -p "  请输入选项: " choice
}

# ---------- 1. 系统状态 ----------
sys_status() {
  clear
  echo -e "${CYAN}────────── 系统状态 ──────────${NC}"
  echo -e "${YELLOW}-- 系统信息 --${NC}"
  echo "  系统: $(. /etc/os-release && echo "$PRETTY_NAME")"
  echo "  内核: $(uname -r) | 架构: $(uname -m)"
  up=$(uptime -p | sed 's/up //')
  up_cn=$(echo "$up" | sed -e 's/years/年/g' -e 's/year/年/g' -e 's/months/个月/g' -e 's/month/个月/g' -e 's/weeks/周/g' -e 's/week/周/g' -e 's/days/天/g' -e 's/day/天/g' -e 's/hours/小时/g' -e 's/hour/小时/g' -e 's/minutes/分钟/g' -e 's/minute/分钟/g' -e 's/less than a minute/不到1分钟/g')
  echo "  运行时长: $up_cn"
  echo "  负载: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
  echo ""

  echo -e "${YELLOW}-- 硬件信息 --${NC}"
  cpu_model=$(grep 'model name' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs)
  [ -z "$cpu_model" ] && cpu_model=$(lscpu | grep -i 'model name' | awk -F: '{print $2}' | xargs)
  echo "  CPU 型号: $cpu_model"
  echo "  CPU 核心: $(nproc) 核"
  cpu_mhz=$(grep 'cpu MHz' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs)
  [ -n "$cpu_mhz" ] && echo "  主频: ${cpu_mhz} MHz"
  mem_type=$(dmidecode -t memory 2>/dev/null | grep -E 'Type:|Speed:' | grep -v 'Unknown\|Not Installed\|{\|}' | head -2 | awk -F: '{print $2}' | xargs)
  [ -n "$mem_type" ] && echo "  内存: $mem_type"
  echo ""

  echo -e "${YELLOW}-- CPU 占用 --${NC}"
  top -bn1 -d 0.1 | awk '/%Cpu/ {printf "  使用率: %.1f%%  (用户 %.1f%% | 系统 %.1f%% | 空闲 %.1f%%)\n", 100-$8, $2, $4, $8}'
  echo "  CPU 占用 TOP5:"
  ps aux --sort=-%cpu | head -6 | awk 'NR>1 {printf "    %-8s %5s%%  %s\n", $1, $3, $11}'
  echo ""

  echo -e "${YELLOW}-- 内存 & Swap --${NC}"
  free -h | awk '
    NR==1 { printf "  %-5s %9s %9s %9s %9s %11s %9s\n", "", "total", "used", "free", "shared", "buff/cache", "avail"; next }
    NR==2 { printf "  %-5s %9s %9s %9s %9s %11s %9s\n", "内存", $2, $3, $4, $5, $6, $7; next }
    NR==3 { printf "  %-5s %9s %9s %9s\n", "交换", $2, $3, $4 }
  '
  echo ""

  echo -e "${YELLOW}-- 磁盘 --${NC}"
  df -h / | awk 'NR==1 { print "  文件系统            容量  已用  可用  使用率  挂载点"; next } { printf "  %-18s %5s %5s %5s %6s  %s\n", $1, $2, $3, $4, $5, $6 }'
  echo ""

  echo -e "${YELLOW}-- 网络信息 --${NC}"
  # 内网 IP
  ip -4 addr show | grep -v '127.0.0.1' | awk '/inet /{print "  内网IP: "$2" ("$NF")"}'
  # 内网 IPv6 (仅全局地址，过滤链路本地 fe80::/10)
  ip -6 addr show scope global 2>/dev/null | awk '/^[0-9]+:/{dev=$2; sub(/:$/,"",dev)} /inet6/{sub(/\/.*/,"",$2); print "  内网IPv6: "$2" ("dev")"}'
  # 默认网关
  gw=$(ip route | awk '/default/{print $3}')
  [ -n "$gw" ] && echo "  默认网关: $gw"
  # DNS
  dns=$(grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ')
  [ -n "$dns" ] && echo "  DNS: $dns"
  echo ""
}

# ---------- 3. 清理垃圾 ----------
fmt_size() {
  local b=$1
  if [ "$b" -ge 1073741824 ]; then
    awk "BEGIN{printf \"%.2fG\", $b/1073741824}"
  elif [ "$b" -ge 1048576 ]; then
    awk "BEGIN{printf \"%.1fM\", $b/1048576}"
  elif [ "$b" -ge 1024 ]; then
    awk "BEGIN{printf \"%.1fK\", $b/1024}"
  else
    echo "${b}B"
  fi
}

sys_clean() {
  while true; do
    clear
    echo -e "${CYAN}────────── 清理垃圾 ──────────${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 清理磁盘垃圾"
    echo -e "   ${GREEN}2${NC}) 清理运行内存"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) clean_disk ;;
      2) clean_memory ;;
      0) return ;;
      *) ;;
    esac
  done
}

clean_disk() {
  clear
  echo -e "${CYAN}────────── 清理磁盘垃圾 ──────────${NC}"
  echo -e "${YELLOW}  将清理: apt 孤儿包 / 下载缓存 / 旧日志 / 过期临时文件${NC}"
  echo -e "${YELLOW}  不影响: 配置、数据、已装软件${NC}"
  if ! confirm "确认开始清理磁盘垃圾?"; then
    echo "  已取消"
    read -p "  按回车继续..."
    return
  fi
  before=$(df -B1 / | awk 'NR==2 {print $3}')
  echo -e "  清理前已用: ${GREEN}$(fmt_size "$before")${NC}"

  echo -e "${YELLOW}[1/4] 清理 apt 无用依赖包...${NC}"
  if apt autoremove -y >/dev/null 2>&1; then echo "  完成"; else echo "  无残留或已是最新"; fi

  echo -e "${YELLOW}[2/4] 清理 apt 下载缓存...${NC}"
  apt clean >/dev/null 2>&1 && echo "  完成"

  echo -e "${YELLOW}[3/4] 压缩系统日志至 50M...${NC}"
  msg=$(journalctl --vacuum-size=50M 2>&1 | tail -1)
  if [ -n "$msg" ]; then echo "  $msg"; else echo "  无可清理日志"; fi

  echo -e "${YELLOW}[4/4] 清理 /var/tmp 中 7 天前的临时文件...${NC}"
  find /var/tmp -type f -atime +7 -delete 2>/dev/null
  echo "  完成"

  after=$(df -B1 / | awk 'NR==2 {print $3}')
  freed=$((before - after))
  [ "$freed" -lt 0 ] && freed=0
  echo ""
  echo -e "  清理前已用: ${GREEN}$(fmt_size "$before")${NC}"
  echo -e "  本次释放:   ${GREEN}$(fmt_size "$freed")${NC}"
  echo -e "  清理后已用: ${GREEN}$(fmt_size "$after")${NC}"
  echo ""
  read -p "  按回车继续..."
}

clean_memory() {
  clear
  echo -e "${CYAN}────────── 清理运行内存 ──────────${NC}"
  echo -e "${YELLOW}  将释放: 页缓存 / 目录项 / inode 缓存${NC}"
  echo -e "${YELLOW}  注意: 清理后系统会重新读磁盘，短暂变慢${NC}"
  echo ""
  if confirm "确认清理运行内存?"; then
    before=$(awk '/^MemTotal/ {total=$2} /^MemAvailable/ {avail=$2} END {printf "%d", (total-avail)/1024}' /proc/meminfo)
    sync
    echo 3 > /proc/sys/vm/drop_caches
    after=$(awk '/^MemTotal/ {total=$2} /^MemAvailable/ {avail=$2} END {printf "%d", (total-avail)/1024}' /proc/meminfo)
    freed=$(awk -v b="$before" -v a="$after" 'BEGIN {printf "%d", b - a}')
    [ -z "$freed" ] && freed=0
    [ "$freed" -lt 0 ] 2>/dev/null && freed=0
    echo -e "  清理后已用: ${GREEN}${after}MB${NC}"
    echo -e "  本次释放:   ${GREEN}${freed}MB${NC}"
  else
    echo "  已取消"
  fi
  read -p "  按回车继续..."
}

# ---------- 软件源管理 ----------
set_apt_source() {
  local base="$1"
  local codename
  codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
  if [ -z "$codename" ]; then
    echo -e "${RED}  无法检测系统代号，已取消${NC}"
    return 1
  fi
  # 备份现有源 (到 /tmp，重启后自动清理，不残留)
  [ -f /etc/apt/sources.list ] && cp /etc/apt/sources.list /tmp/apt-sources.list.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null
  [ -f /etc/apt/sources.list.d/debian.sources ] && cp /etc/apt/sources.list.d/debian.sources /tmp/apt-debian.sources.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null
  cat > /etc/apt/sources.list <<EOF
deb ${base}/debian ${codename} main contrib non-free non-free-firmware
deb ${base}/debian-security ${codename}-security main contrib non-free non-free-firmware
deb ${base}/debian ${codename}-updates main contrib non-free non-free-firmware
EOF
  # 删除 deb822 格式文件避免冲突
  rm -f /etc/apt/sources.list.d/debian.sources
  # 不静默，让用户看到 update 结果
  apt update
}

sys_apt_sources() {
  local codename
  codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
  while true; do
    clear
    echo -e "${CYAN}────────── 软件源管理 ──────────${NC}"
    echo -e "  系统: $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo -e "  代号: ${codename}"
    echo ""
    echo -e "${YELLOW}-- 当前源配置 --${NC}"
    if [ -f /etc/apt/sources.list ]; then
      grep -vE '^\s*#|^\s*$' /etc/apt/sources.list | head -10
    fi
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
      echo "  (deb822 格式文件存在)"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 更新软件源"
    echo -e "   ${GREEN}2${NC}) 升级系统"
    echo -e "   ${GREEN}3${NC}) 设置为 Debian 官方源"
    echo -e "   ${GREEN}4${NC}) 设置为 清华大学源"
    echo -e "   ${GREEN}5${NC}) 设置为 阿里云源"
    echo -e "   ${GREEN}6${NC}) 手动管理源"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        if confirm "确认更新软件源?"; then
          echo -e "${YELLOW}  正在 apt update...${NC}"
          if apt update; then
            echo -e "${GREEN}  软件源已更新${NC}"
          else
            echo -e "${RED}  apt update 有错误，请检查网络或源配置${NC}"
          fi
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      2)
        if confirm "确认升级系统? (apt upgrade)"; then
          echo -e "${YELLOW}  正在升级系统...${NC}"
          apt upgrade -y
          echo -e "${GREEN}  系统升级完成${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      3)
        if confirm "确认切换为 Debian 官方源?"; then
          if set_apt_source "http://deb.debian.org"; then
            echo -e "${GREEN}  已切换为 Debian 官方源 (deb.debian.org)${NC}"
          else
            echo -e "${RED}  源文件已写入，但 apt update 有错误，请检查网络${NC}"
          fi
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      4)
        if confirm "确认切换为 清华大学源?"; then
          if set_apt_source "https://mirrors.tuna.tsinghua.edu.cn"; then
            echo -e "${GREEN}  已切换为 清华大学源 (mirrors.tuna.tsinghua.edu.cn)${NC}"
          else
            echo -e "${RED}  源文件已写入，但 apt update 有错误，请检查网络${NC}"
          fi
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      5)
        if confirm "确认切换为 阿里云源?"; then
          if set_apt_source "https://mirrors.aliyun.com"; then
            echo -e "${GREEN}  已切换为 阿里云源 (mirrors.aliyun.com)${NC}"
          else
            echo -e "${RED}  源文件已写入，但 apt update 有错误，请检查网络${NC}"
          fi
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      6) sys_apt_manual ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 软件源: 手动管理 ----------
sys_apt_manual() {
  local src="/etc/apt/sources.list"
  while true; do
    clear
    echo -e "${CYAN}────────── 手动管理源 ──────────${NC}"
    echo -e "  文件: ${GREEN}${src}${NC}"
    echo ""
    if [ -f "$src" ]; then
      cat -n "$src"
    else
      echo "  (文件不存在)"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 添加源"
    echo -e "   ${GREEN}2${NC}) 编辑源"
    echo -e "   ${GREEN}3${NC}) 删除源"
    echo -e "   ${GREEN}0${NC}) 返回"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  输入完整源行: " line
        if echo "$line" | grep -qE '^deb\s+'; then
          echo "$line" >> "$src"
          echo -e "${GREEN}  已添加${NC}"
        else
          echo -e "${RED}  格式错误，必须以 deb 开头${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      2)
        read -p "  行号+空格+新内容: " input
        num=$(echo "$input" | awk '{print $1}')
        line=$(echo "$input" | cut -d' ' -f2-)
        total=$(awk 'END{print NR}' "$src" 2>/dev/null || echo 0)
        if echo "$num" | grep -qE '^[0-9]+$' && [ "$num" -ge 1 ] && [ "$num" -le "$total" ] && echo "$line" | grep -qE '^deb\s+'; then
          sed -i "${num}c\\${line}" "$src"
          echo -e "${GREEN}  第 ${num} 行已更新${NC}"
        else
          echo -e "${RED}  无效行号或格式错误 (1-${total}，内容需以 deb 开头)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      3)
        read -p "  行号 (0=删除所有): " num
        total=$(awk 'END{print NR}' "$src" 2>/dev/null || echo 0)
        if [ "$num" = "0" ]; then
          if [ "$total" -eq 0 ]; then
            echo -e "${YELLOW}  源列表已经是空的${NC}"
          elif confirm "确认删除所有源 (共 ${total} 行)?"; then
            > "$src"
            echo -e "${GREEN}  已删除所有源${NC}"
          else
            echo "  已取消"
          fi
        elif echo "$num" | grep -qE '^[0-9]+$' && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
          if confirm "确认删除第 ${num} 行?"; then
            sed -i "${num}d" "$src"
            echo -e "${GREEN}  第 ${num} 行已删除${NC}"
          else
            echo "  已取消"
          fi
        else
          echo -e "${RED}  无效行号 (0-${total})${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 4. 系统工具 (虚拟内存) ----------
swap_status() {
  if swapon --show | grep -q 'swapfile'; then
    echo -e "  当前状态: ${GREEN}已开启${NC}"
  else
    echo -e "  当前状态: ${RED}未开启${NC}"
    if [ -f /swapfile ]; then
      echo -e "  文件存在: /swapfile，尚未启用"
    fi
  fi
}

swap_create() {
  read -p "  输入虚拟内存大小 (MB): " size
  if echo "$size" | grep -qE '^[0-9]+$' && [ "$size" -ge 16 ] && [ "$size" -le 8192 ]; then
    echo -e "${YELLOW}  正在创建 ${size}M 虚拟内存...${NC}"
    if fallocate -l "${size}M" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$size" 2>/dev/null; then
      chmod 600 /swapfile
      mkswap /swapfile >/dev/null 2>&1
      swapon /swapfile
      grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
      echo -e "${GREEN}  创建完成! 当前: $(free -h | awk '/Swap/ {print $2}')${NC}"
    else
      echo -e "${RED}  创建失败 (磁盘空间不足?)${NC}"
    fi
  else
    echo -e "${RED}  无效大小 (16-8192 MB)${NC}"
  fi
  read -p "  按回车继续..."
}

swap_set_size() {
  read -p "  输入新的大小 (MB): " size
  if echo "$size" | grep -qE '^[0-9]+$' && [ "$size" -ge 16 ] && [ "$size" -le 8192 ]; then
    echo -e "${YELLOW}  正在调整虚拟内存为 ${size}M...${NC}"
    swapoff /swapfile 2>/dev/null
    rm -f /swapfile
    if fallocate -l "${size}M" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$size" 2>/dev/null; then
      chmod 600 /swapfile
      mkswap /swapfile >/dev/null 2>&1
      swapon /swapfile
      grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
      echo -e "${GREEN}  调整完成! 当前: $(free -h | awk '/Swap/ {print $2}')${NC}"
    else
      echo -e "${RED}  调整失败 (磁盘空间不足?)${NC}"
    fi
  else
    echo -e "${RED}  无效大小 (16-8192 MB)${NC}"
  fi
  read -p "  按回车继续..."
}

swap_toggle() {
  if swapon --show | grep -q 'swapfile'; then
    if confirm "确认关闭虚拟内存?"; then
      swapoff /swapfile && echo -e "${YELLOW}  虚拟内存已关闭 (仅本次生效，重启后自动恢复)${NC}"
    else
      echo "  已取消"
    fi
  else
    if [ -f /swapfile ]; then
      if confirm "确认开启虚拟内存?"; then
        swapon /swapfile && echo -e "${GREEN}  虚拟内存已开启${NC}"
      else
        echo "  已取消"
      fi
    else
      echo -e "${RED}  无虚拟内存文件，请先设置大小${NC}"
    fi
  fi
  read -p "  按回车继续..."
}

swap_delete() {
  if confirm "确认删除虚拟内存?"; then
    swapoff /swapfile 2>/dev/null
    rm -f /swapfile
    sed -i '/swapfile/d' /etc/fstab
    echo -e "${GREEN}  已删除虚拟内存 (零残留)${NC}"
  else
    echo "  已取消"
  fi
  read -p "  按回车继续..."
}

sys_swap() {
  clear
  echo -e "${CYAN}────────── 虚拟内存设置 ──────────${NC}"
  swap_status
  echo ""
  # 完全没有虚拟内存：询问是否新建
  if ! swapon --show | grep -q 'swapfile' && [ ! -f /swapfile ]; then
    echo -e "${YELLOW}  未检测到虚拟内存${NC}"
    if confirm "是否新建虚拟内存?"; then
      swap_create
    else
      echo "  已取消"
      read -p "  按回车返回..."
      return
    fi
  fi
  while true; do
    clear
    echo -e "${CYAN}────────── 虚拟内存设置 ──────────${NC}"
    swap_status
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 设置虚拟内存大小"
    echo -e "   ${GREEN}2${NC}) 开启/关闭虚拟内存"
    echo -e "   ${GREEN}3${NC}) 删除虚拟内存"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) swap_set_size ;;
      2) swap_toggle ;;
      3) swap_delete ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- SSH 端口修改 ----------
sys_ssh_port() {
  local cur_port
  cur_port=$(grep -E '^#?Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -1)
  [ -z "$cur_port" ] && cur_port=22
  while true; do
    clear
    echo -e "${CYAN}────────── SSH 端口修改 ──────────${NC}"
    echo ""
    echo -e "  当前 SSH 端口: ${GREEN}$cur_port${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 修改端口"
    echo -e "   ${GREEN}0${NC}) 返回"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  输入新端口 (1-65535): " newport
        if ! echo "$newport" | grep -qE '^[0-9]+$' || [ "$newport" -lt 1 ] || [ "$newport" -gt 65535 ]; then
          echo -e "${RED}  无效端口${NC}"
          read -p "  按回车继续..."
          continue
        fi
        if [ "$newport" = "$cur_port" ]; then
          echo -e "${YELLOW}  端口未变，和当前一致${NC}"
          read -p "  按回车继续..."
          continue
        fi
        # 检查端口是否被占用
        if ss -tlnp | grep -q ":${newport} "; then
          echo -e "${RED}  端口 $newport 已被其他程序占用${NC}"
          read -p "  按回车继续..."
          continue
        fi
        # 检查 ufw
        local ufw_installed=0
        local ufw_active=0
        command -v ufw >/dev/null 2>&1 && ufw_installed=1
        if [ "$ufw_installed" = "1" ]; then
          ufw status 2>/dev/null | grep -q "Status: active" && ufw_active=1
        fi
        if [ "$ufw_installed" = "0" ]; then
          echo -e "${YELLOW}  需要在防火墙放行新端口再修改${NC}"
          if ! confirm "确认继续修改?"; then
            echo "  已取消"
            read -p "  按回车继续..."
            continue
          fi
        elif [ "$ufw_active" = "0" ]; then
          echo -e "${YELLOW}  ufw 已安装但未启用${NC}"
          if confirm "是否启用 ufw 并自动放行新端口?"; then
            # 先放行旧端口和新端口，防止锁死
            ufw allow ${cur_port}/tcp >/dev/null 2>&1
            ufw allow ${newport}/tcp >/dev/null 2>&1
            ufw --force enable >/dev/null 2>&1
            echo -e "${GREEN}  ufw 已启用，${newport}/tcp 已放行${NC}"
          else
            echo -e "${YELLOW}  未启用 ufw，请自行在防火墙放行新端口${NC}"
            if ! confirm "确认继续修改?"; then
              echo "  已取消"
              read -p "  按回车继续..."
              continue
            fi
          fi
        else
          # 检查新端口是否已放行
          if ufw status | grep -q "^${newport}/tcp"; then
            echo -e "  新端口 ${GREEN}$newport/tcp${NC} 已在防火墙放行"
          else
            if ! confirm "新端口 $newport/tcp 未放行，将自动放行，是否继续?"; then
              echo "  已取消"
              read -p "  按回车继续..."
              continue
            fi
            ufw allow ${newport}/tcp >/dev/null 2>&1
            echo -e "${GREEN}  已自动放行 ${newport}/tcp${NC}"
          fi
        fi
        # 修改 sshd_config (备份到 /tmp，用完即删，不残留)
        local bakfile="/tmp/sshd_config.bak.$SECONDS"
        cp /etc/ssh/sshd_config "$bakfile" 2>/dev/null
        # 删除所有 Port 行，再添加新的
        sed -i '/^#*Port /d' /etc/ssh/sshd_config
        echo "Port $newport" >> /etc/ssh/sshd_config
        # 重启 sshd 并检查是否成功
        if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; then
          sleep 1
          if ss -tlnp | grep -q ":${newport} "; then
            cur_port="$newport"
            echo -e "${GREEN}  SSH 端口已修改为 $newport${NC}"
          else
            echo -e "${RED}  警告: sshd 重启后新端口未监听，正在回滚...${NC}"
            cp "$bakfile" /etc/ssh/sshd_config 2>/dev/null
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
            echo -e "${YELLOW}  已回滚到原配置，端口未修改${NC}"
          fi
        else
          echo -e "${RED}  警告: sshd 重启失败，正在回滚...${NC}"
          cp "$bakfile" /etc/ssh/sshd_config 2>/dev/null
          systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
          echo -e "${YELLOW}  已回滚到原配置，端口未修改${NC}"
        fi
        rm -f "$bakfile" 2>/dev/null
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 4. 系统工具 (总入口) ----------
sys_timezone() {
  while true; do
    clear
    cur=$(timedatectl show -p Timezone --value 2>/dev/null)
    echo -e "${CYAN}────────── 设置时区 ──────────${NC}"
    echo -e "  当前时区: ${GREEN}${cur:-未知}${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 中国北京  (Asia/Shanghai)"
    echo -e "   ${GREEN}2${NC}) 中国香港  (Asia/Hong_Kong)"
    echo -e "   ${GREEN}3${NC}) 中国台湾  (Asia/Taipei)"
    echo -e "   ${GREEN}4${NC}) 日本      (Asia/Tokyo)"
    echo -e "   ${GREEN}5${NC}) 韩国      (Asia/Seoul)"
    echo -e "   ${GREEN}6${NC}) 新加坡    (Asia/Singapore)"
    echo -e "   ${GREEN}7${NC}) 美国东部  (America/New_York)"
    echo -e "   ${GREEN}8${NC}) 美国西部  (America/Los_Angeles)"
    echo -e "   ${GREEN}9${NC}) 英国      (Europe/London)"
    echo -e "  ${GREEN}10${NC}) 德国      (Europe/Berlin)"
    echo -e "  ${GREEN}11${NC}) 俄罗斯    (Europe/Moscow)"
    echo -e "  ${GREEN}12${NC}) 澳大利亚  (Australia/Sydney)"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) tz="Asia/Shanghai" ;;
      2) tz="Asia/Hong_Kong" ;;
      3) tz="Asia/Taipei" ;;
      4) tz="Asia/Tokyo" ;;
      5) tz="Asia/Seoul" ;;
      6) tz="Asia/Singapore" ;;
      7) tz="America/New_York" ;;
      8) tz="America/Los_Angeles" ;;
      9) tz="Europe/London" ;;
      10) tz="Europe/Berlin" ;;
      11) tz="Europe/Moscow" ;;
      12) tz="Australia/Sydney" ;;
      0) return ;;
      *) continue ;;
    esac
    if timedatectl set-timezone "$tz" 2>/dev/null; then
      echo -e "${GREEN}  时区已设置为: $tz${NC}"
    else
      echo -e "${RED}  设置失败${NC}"
    fi
    read -p "  按回车继续..."
  done
}

sys_locale() {
  while true; do
    clear
    cur=$LANG
    echo -e "${CYAN}────────── 设置语言 ──────────${NC}"
    echo -e "  当前语言: ${GREEN}${cur:-en_US.UTF-8}${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 简体中文  (zh_CN.UTF-8)"
    echo -e "   ${GREEN}2${NC}) 繁体中文  (zh_TW.UTF-8)"
    echo -e "   ${GREEN}3${NC}) 英语(美)  (en_US.UTF-8)"
    echo -e "   ${GREEN}4${NC}) 英语(英)  (en_GB.UTF-8)"
    echo -e "   ${GREEN}5${NC}) 日语      (ja_JP.UTF-8)"
    echo -e "   ${GREEN}6${NC}) 韩语      (ko_KR.UTF-8)"
    echo -e "   ${GREEN}7${NC}) 德语      (de_DE.UTF-8)"
    echo -e "   ${GREEN}8${NC}) 法语      (fr_FR.UTF-8)"
    echo -e "   ${GREEN}9${NC}) 俄语      (ru_RU.UTF-8)"
    echo -e "  ${GREEN}10${NC}) 西班牙语  (es_ES.UTF-8)"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) loc="zh_CN.UTF-8" ;;
      2) loc="zh_TW.UTF-8" ;;
      3) loc="en_US.UTF-8" ;;
      4) loc="en_GB.UTF-8" ;;
      5) loc="ja_JP.UTF-8" ;;
      6) loc="ko_KR.UTF-8" ;;
      7) loc="de_DE.UTF-8" ;;
      8) loc="fr_FR.UTF-8" ;;
      9) loc="ru_RU.UTF-8" ;;
      10) loc="es_ES.UTF-8" ;;
      0) return ;;
      *) continue ;;
    esac
    # 确保 locales 包已安装
    if ! command -v locale-gen >/dev/null 2>&1; then
      echo -e "${YELLOW}  未安装 locales，正在安装...${NC}"
      apt install -y locales >/dev/null 2>&1 || { echo -e "${RED}  安装失败，请检查网络${NC}"; read -p "  按回车继续..."; continue; }
    fi
    # 确保该语言已生成
    if ! locale -a 2>/dev/null | grep -qi "${loc%.*}"; then
      locale-gen "$loc" >/dev/null 2>&1
    fi
    update-locale LANG="$loc" >/dev/null 2>&1
    echo -e "${GREEN}  语言已设置为: $loc (重连 SSH 后生效)${NC}"
    read -p "  按回车继续..."
  done
}

sys_hostname() {
  # 首次运行：记录初始主机名并写回脚本自身
  if [ -z "$ORIG_HOSTNAME" ] && [ -f /etc/hostname ]; then
    self=$(readlink -f "$0")
    orig=$(cat /etc/hostname)
    sed -i "s/^ORIG_HOSTNAME=\"\"$/ORIG_HOSTNAME=\"$orig\"/" "$self" 2>/dev/null
    ORIG_HOSTNAME="$orig"
  fi
  while true; do
    clear
    cur=$(cat /etc/hostname 2>/dev/null || echo "unknown")
    echo -e "${CYAN}────────── 设置主机名 ──────────${NC}"
    echo -e "  当前主机名: ${GREEN}${cur}${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 修改主机名"
    echo -e "   ${GREEN}2${NC}) 恢复默认"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  输入新主机名 (仅限字母/数字/连字符): " new
        if echo "$new" | grep -qE '^[a-zA-Z0-9]$|^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$'; then
          if hostnamectl set-hostname "$new" 2>/dev/null; then
            sed -i "s/127\.0\.1\.1.*/127.0.1.1 $new/" /etc/hosts
            echo -e "${GREEN}  主机名已改为: $new${NC}"
          else
            echo -e "${RED}  修改失败${NC}"
          fi
        else
          echo -e "${RED}  无效主机名 (仅限字母/数字/连字符，1-64字符)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      2)
        target="${ORIG_HOSTNAME:-debian}"
        if hostnamectl set-hostname "$target" 2>/dev/null; then
          sed -i "s/127\.0\.1\.1.*/127.0.1.1 $target/" /etc/hosts
          echo -e "${GREEN}  已恢复初始主机名: $target${NC}"
        else
          echo -e "${RED}  恢复失败${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

sys_passwd() {
  while true; do
    clear
    echo -e "${CYAN}────────── 设置登录密码 ──────────${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 修改 root 密码"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        echo -e "${YELLOW}  请输入新密码 (输入时不显示):${NC}"
        read -rs p1
        echo ""
        echo -e "${YELLOW}  请再次输入确认:${NC}"
        read -rs p2
        echo ""
        if [ -z "$p1" ]; then
          echo -e "${RED}  密码不能为空${NC}"
        elif echo "$p1" | grep -q ':'; then
          echo -e "${RED}  密码不能包含冒号，已取消${NC}"
        elif [ "$p1" != "$p2" ]; then
          echo -e "${RED}  两次输入不一致，已取消${NC}"
        elif echo "root:$p1" | chpasswd 2>/dev/null; then
          echo -e "${GREEN}  密码修改成功${NC}"
        else
          echo -e "${RED}  修改失败${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

sys_hotkey_inline() {
  self_path=$(readlink -f "$0")
  read -p "  输入新快捷键 (如 e、m，仅限字母数字): " new
  if echo "$new" | grep -qE '^[a-zA-Z0-9]{1,16}$'; then
    newpath="/usr/local/bin/$new"
    if [ -e "$newpath" ] && [ "$newpath" != "$self_path" ]; then
      echo -e "${RED}  $newpath 已存在，请换个名字${NC}"
    elif [ "$newpath" = "$self_path" ]; then
      echo -e "${YELLOW}  快捷键未变化${NC}"
    else
      mv "$self_path" "$newpath" && {
        SCRIPT_PATH="$newpath"
        echo -e "${GREEN}  快捷键已改为: $new (下次输入 $new 打开)${NC}"
      } || echo -e "${RED}  修改失败 (权限不足?)${NC}"
    fi
  else
    echo -e "${RED}  无效输入 (仅限字母数字，16字符内)${NC}"
  fi
  read -p "  按回车继续..."
}

sys_schedule_reboot() {
  while true; do
    clear
    echo -e "${CYAN}────────── 定时重启 ──────────${NC}"
    echo ""
    if [ -f /etc/systemd/system/reboot.timer ]; then
      interval=$(grep -oE 'OnUnitActiveSec=[^ ]+' /etc/systemd/system/reboot.timer 2>/dev/null | cut -d= -f2)
      hours=${interval%h}
      active=$(systemctl is-active reboot.timer 2>/dev/null)
      echo -e "  当前状态: ${GREEN}已设置${NC}"
      echo -e "  重启周期: 每 ${hours:-?} 小时一次"
      echo -e "  定时器:   ${active}"
    else
      echo -e "  当前状态: ${YELLOW}未设置定时重启${NC}"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 设置重启时间"
    echo -e "   ${GREEN}2${NC}) 取消定时重启"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  每多少小时重启一次 (1-168): " h
        if echo "$h" | grep -qE '^[0-9]+$' && [ "$h" -ge 1 ] && [ "$h" -le 168 ]; then
          if confirm "确认设置每 ${h} 小时重启一次?"; then
            cat > /etc/systemd/system/reboot.service <<EOF
[Unit]
Description=Scheduled Reboot
[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl reboot
EOF
            cat > /etc/systemd/system/reboot.timer <<EOF
[Unit]
Description=Scheduled Reboot Timer
[Timer]
OnBootSec=${h}h
OnUnitActiveSec=${h}h
[Install]
WantedBy=timers.target
EOF
            systemctl daemon-reload
            systemctl enable --now reboot.timer >/dev/null 2>&1
            echo -e "${GREEN}  已设置: 每 ${h} 小时重启一次${NC}"
          else
            echo "  已取消"
          fi
        else
          echo -e "${RED}  无效输入 (1-168 小时)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      2)
        if [ ! -f /etc/systemd/system/reboot.timer ]; then
          echo -e "${YELLOW}  未设置定时重启，无需取消${NC}"
        elif confirm "确认取消定时重启?"; then
          systemctl disable --now reboot.timer >/dev/null 2>&1
          rm -f /etc/systemd/system/reboot.service /etc/systemd/system/reboot.timer
          systemctl daemon-reload
          echo -e "${GREEN}  已取消定时重启${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

sys_reboot() {
  clear
  echo -e "${CYAN}────────── 重启服务器 ──────────${NC}"
  echo -e "${YELLOW}  重启后 SSH 会断开，请稍等再重新连接${NC}"
  if confirm "确认重启服务器?"; then
    echo -e "${YELLOW}  服务器重启中...${NC}"
    reboot
  else
    echo "  已取消"
    read -p "  按回车继续..."
  fi
}

sys_update() {
  if confirm "确认更新脚本?"; then
    echo -e "${YELLOW}  正在下载...${NC}"
    if curl -sL https://raw.githubusercontent.com/smallsmalldou/Easylinux/main/e -o "$SCRIPT_PATH" && chmod +x "$SCRIPT_PATH"; then
      echo -e "${GREEN}  更新完成，即将重启脚本...${NC}"
      sleep 1
      exec "$SCRIPT_PATH"
    else
      echo -e "${RED}  更新失败，请检查网络或 GitHub 地址${NC}"
      read -p "  按回车继续..."
    fi
  else
    echo "  已取消"
    read -p "  按回车继续..."
  fi
}

sys_script_mgmt() {
  while true; do
    self_path="$SCRIPT_PATH"
    cur_name=$(basename "$self_path")
    clear
    echo -e "${CYAN}────────── Easy 脚本管理 ──────────${NC}"
    echo ""
    echo -e "  当前启动快捷键: ${GREEN}${cur_name}${NC}"
    echo -e "${YELLOW}  更新: 将从 GitHub 下载最新版脚本覆盖当前版本${NC}"
    echo -e "${YELLOW}  仓库: https://github.com/smallsmalldou/Easylinux${NC}"
    echo -e "${YELLOW}  卸载: 将删除脚本 ${self_path}${NC}"
    echo -e "${YELLOW}  注意: 卸载会同时删除您的笔记文件${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 设置脚本快捷键"
    echo -e "   ${GREEN}2${NC}) 更新脚本"
    echo -e "   ${GREEN}3${NC}) 卸载脚本"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) sys_hotkey_inline ;;
      2) sys_update ;;
      3) sys_uninstall ;;
      0) return ;;
      *) ;;
    esac
  done
}

sys_uninstall() {
  self_path="$SCRIPT_PATH"
  if confirm "确认卸载脚本?"; then
    rm -f "$self_path"
    rm -f "$NOTES_FILE"
    echo -e "${GREEN}  已卸载，脚本和笔记文件已删除${NC}"
    exit 0
  else
    echo "  已取消"
    read -p "  按回车继续..."
  fi
}

# ---------- 9. 上网设置 ----------
# 切换 IPv4/IPv6 上网模式：单 IPv4（禁用 IPv6）或双栈（IPv4+IPv6 同时）
# 持久化到 /etc/sysctl.d/99-ipv6.conf，重启后保持；sysctl -p 立即生效
sys_netmode() {
  while true; do
    clear
    echo -e "${CYAN}────────── 上网设置 ──────────${NC}"
    echo ""
    echo -e "${YELLOW}-- 当前上网模式 --${NC}"
    if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)" = "1" ]; then
      echo -e "   ${GREEN}单 IPv4 上网${NC} (IPv6 已禁用)"
    else
      echo -e "   ${GREEN}IPv4 + IPv6 双栈上网${NC}"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 单 IPv4 上网"
    echo -e "   ${GREEN}2${NC}) IPv4 + IPv6 双栈上网"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        if confirm "确认切换为单 IPv4 上网? (将禁用 IPv6，SSH 走 IPv4 不受影响)"; then
          if printf 'net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\n' > /etc/sysctl.d/99-ipv6.conf 2>/dev/null; then
            sysctl -p /etc/sysctl.d/99-ipv6.conf >/dev/null 2>&1
            echo -e "${GREEN}  已切换为单 IPv4 上网 (重启后保持)${NC}"
          else
            echo -e "${RED}  写入失败 (权限不足或磁盘只读)，未生效${NC}"
          fi
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      2)
        if confirm "确认切换为 IPv4 + IPv6 双栈上网? (将重新启用 IPv6)"; then
          if printf 'net.ipv6.conf.all.disable_ipv6 = 0\nnet.ipv6.conf.default.disable_ipv6 = 0\n' > /etc/sysctl.d/99-ipv6.conf 2>/dev/null; then
            sysctl -p /etc/sysctl.d/99-ipv6.conf >/dev/null 2>&1
            echo -e "${GREEN}  已切换为 IPv4 + IPv6 双栈上网 (重启后保持)${NC}"
          else
            echo -e "${RED}  写入失败 (权限不足或磁盘只读)，未生效${NC}"
          fi
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

sys_tools() {
  while true; do
    clear
    echo -e "${CYAN}────────── 系统工具 ──────────${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 软件源管理     ${GREEN}11${NC}) Easy 脚本管理"
    echo -e "   ${GREEN}2${NC}) 虚拟内存设置"
    echo -e "   ${GREEN}3${NC}) 上网设置"
    echo -e "   ${GREEN}4${NC}) SSH 端口修改"
    echo -e "   ${GREEN}5${NC}) 设置时区"
    echo -e "   ${GREEN}6${NC}) 设置语言"
    echo -e "   ${GREEN}7${NC}) 设置主机名"
    echo -e "   ${GREEN}8${NC}) 设置登录密码"
    echo -e "   ${GREEN}9${NC}) 定时重启"
    echo -e "  ${GREEN}10${NC}) 重启服务器"
    echo ""
    echo -e "               ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) sys_apt_sources ;;
      2) sys_swap ;;
      3) sys_netmode ;;
      4) sys_ssh_port ;;
      5) sys_timezone ;;
      6) sys_locale ;;
      7) sys_hostname ;;
      8) sys_passwd ;;
      9) sys_schedule_reboot ;;
      10) sys_reboot ;;
      11) sys_script_mgmt ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 端口输入校验 ----------
port_check() {
  case "$1" in
    */*)
      num=${1%/*}
      proto=${1#*/}
      if echo "$num" | grep -qE '^[0-9]{1,5}$' && [ "$num" -ge 1 ] && [ "$num" -le 65535 ] && { [ "$proto" = "tcp" ] || [ "$proto" = "udp" ]; }; then
        return 0
      fi
      return 1
      ;;
    *)
      if echo "$1" | grep -qE '^[0-9]{1,5}$' && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; then
        return 0
      fi
      return 1
      ;;
  esac
}

# ---------- 5. 端口状态 ----------
sys_ports() {
  clear
  echo -e "${CYAN}────────── 端口状态 ──────────${NC}"
  echo -e "${YELLOW}-- 当前监听的端口 --${NC}"
  if command -v ss >/dev/null 2>&1; then
    ss -tunlp | awk '
      NR==1 {
        print "  协议    状态        收队列  发队列  本地地址:端口                      对端地址:端口                进程"
        next
      }
      {
        proc=$7
        if (proc == "") proc = "-"
        else {
          sub(/^users:\(\(/, "", proc)
          sub(/\)\)$/, "", proc)
          gsub(/"/, "", proc)
          gsub(/,pid=/, " (pid:", proc)
          gsub(/,fd=[0-9]+/, "", proc)
        }
        printf "  %-6s %-9s %6s %6s  %-38s %-24s %s\n", $1, $2, $3, $4, $5, $6, proc
      }
    '
    echo ""
    n=$(ss -tunlp | grep -cE 'LISTEN|UNCONN')
    echo -e "  共监听 ${GREEN}${n}${NC} 个端口"
  else
    echo -e "${RED}  未找到 ss 命令 (缺少 iproute2)${NC}"
  fi
  read -p "  按回车返回菜单..."
}

# ---------- 7. BBR 加速 ----------
# 判断 BBR 是否已安装 (存在持久化配置)
bbr_installed() {
  [ -f /etc/sysctl.d/99-bbr.conf ] || [ -f /etc/modules-load.d/bbr.conf ]
}

bbr_status() {
  algo=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)
  if [ "$algo" = "bbr" ]; then
    echo -e "  当前状态: ${GREEN}已生效${NC}"
    echo -e "  队列算法: $(cat /proc/sys/net/core/default_qdisc 2>/dev/null)"
  elif bbr_installed; then
    echo -e "  当前状态: ${YELLOW}已临时停用${NC}"
    echo -e "  当前算法: ${algo:-未知}，重启后恢复 BBR"
  else
    echo -e "  当前状态: ${RED}已停用${NC}"
    echo -e "  系统默认规则: ${algo:-未知}"
    if lsmod | grep -q tcp_bbr; then
      echo -e "  内核支持: ${GREEN}支持 (模块可用)${NC}"
    elif modprobe -n tcp_bbr 2>/dev/null; then
      echo -e "  内核支持: ${GREEN}支持${NC}"
    else
      echo -e "  内核支持: ${RED}不支持${NC}"
    fi
  fi
}

# 核心安装动作: 加载模块 + 写持久化配置 + 立即生效
bbr_do_install() {
  if ! modprobe tcp_bbr 2>/dev/null; then
    echo -e "${RED}  内核不支持 BBR，无法安装${NC}"
    echo -e "  需要更新内核 (如安装 linux-image-amd64) 才能使用 BBR"
    return 1
  fi
  mkdir -p /etc/modules-load.d /etc/sysctl.d
  echo 'tcp_bbr' > /etc/modules-load.d/bbr.conf
  cat > /etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  sed -i '/^net.core.default_qdisc=/d; /^net.ipv4.tcp_congestion_control=/d' /etc/sysctl.conf
  sysctl --system >/dev/null 2>&1
  if [ "$(cat /proc/sys/net/ipv4/tcp_congestion_control)" = "bbr" ]; then
    echo -e "${GREEN}  BBR 安装完成 (开机自启 + 已生效)${NC}"
  else
    echo -e "${RED}  安装失败，当前算法: $(cat /proc/sys/net/ipv4/tcp_congestion_control)${NC}"
  fi
}

bbr_install() {
  if bbr_installed; then
    if confirm "BBR 已安装，是否全新安装?"; then
      bbr_do_install
    else
      echo "  已取消"
    fi
  else
    if confirm "确认安装 BBR?"; then
      bbr_do_install
    else
      echo "  已取消"
    fi
  fi
}

bbr_enable() {
  if ! bbr_installed; then
    echo -e "${YELLOW}  BBR 尚未安装，请先选择 1 安装${NC}"
    return
  fi
  if confirm "确认启用 BBR?"; then
    modprobe tcp_bbr 2>/dev/null
    sysctl --system >/dev/null 2>&1
    if [ "$(cat /proc/sys/net/ipv4/tcp_congestion_control)" = "bbr" ]; then
      echo -e "${GREEN}  BBR 已启用${NC}"
    else
      echo -e "${RED}  启用失败，当前算法: $(cat /proc/sys/net/ipv4/tcp_congestion_control)${NC}"
    fi
  else
    echo "  已取消"
  fi
}

# 移除 BBR 配置并切回系统默认
bbr_remove() {
  rm -f /etc/sysctl.d/99-bbr.conf /etc/modules-load.d/bbr.conf
  sed -i '/^net.core.default_qdisc=/d; /^net.ipv4.tcp_congestion_control=/d' /etc/sysctl.conf
  sysctl -w net.ipv4.tcp_congestion_control=cubic net.core.default_qdisc=fq_codel >/dev/null 2>&1
}

bbr_disable() {
  if ! bbr_installed; then
    echo -e "${YELLOW}  BBR 未安装，当前就是系统默认，无需停用${NC}"
    return
  fi
  if confirm "确认临时停用 BBR (重启后恢复)?"; then
    sysctl -w net.ipv4.tcp_congestion_control=cubic net.core.default_qdisc=fq_codel >/dev/null 2>&1
    echo -e "${YELLOW}  已临时停用 BBR，当前使用系统默认: $(cat /proc/sys/net/ipv4/tcp_congestion_control)，重启后恢复 BBR${NC}"
  else
    echo "  已取消"
  fi
}

bbr_uninstall() {
  if ! bbr_installed; then
    echo -e "${YELLOW}  BBR 未安装，无需卸载${NC}"
    return
  fi
  if confirm "确认卸载 BBR (将彻底移除)?"; then
    bbr_remove
    if rmmod tcp_bbr 2>/dev/null; then
      echo -e "${YELLOW}  已彻底卸载 BBR，系统恢复默认: $(cat /proc/sys/net/ipv4/tcp_congestion_control)${NC}"
    else
      echo -e "${YELLOW}  配置已删除，模块无法立即移除，重启后自动消失${NC}"
    fi
  else
    echo "  已取消"
  fi
}

sys_bbr() {
  while true; do
    clear
    echo -e "${CYAN}────────── BBR 加速 ──────────${NC}"
    bbr_status
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 安装 BBR"
    echo -e "   ${GREEN}2${NC}) 启用 BBR"
    echo -e "   ${GREEN}3${NC}) 停用 BBR"
    echo -e "   ${GREEN}4${NC}) 卸载 BBR"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) bbr_install; read -p "  按回车继续..." ;;
      2) bbr_enable; read -p "  按回车继续..." ;;
      3) bbr_disable; read -p "  按回车继续..." ;;
      4) bbr_uninstall; read -p "  按回车继续..." ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 6. 防火墙管理 ----------
# 放行/取消端口 (v4/v6 分离)：$1=v4|v6  $2=allow|delete  $3=端口(80|80/tcp|80/udp)
# v4 用 0.0.0.0/0、v6 用 ::/0 限定地址族，只生成对应 iptables/ip6tables 规则
fw_port() {
  local family="$1" act="$2" port="$3" src pnum pproto
  if [ "$family" = "v4" ]; then
    src="0.0.0.0/0"
  else
    src="::/0"
  fi
  if [[ "$port" == */* ]]; then
    pnum=${port%/*}
    pproto=${port#*/}
    if [ "$act" = "allow" ]; then
      ufw allow from "$src" to any port "$pnum" proto "$pproto"
    else
      ufw delete allow from "$src" to any port "$pnum" proto "$pproto"
    fi
  else
    if [ "$act" = "allow" ]; then
      ufw allow from "$src" to any port "$port"
    else
      ufw delete allow from "$src" to any port "$port"
    fi
  fi
}

sys_ufw() {
  if ! command -v ufw >/dev/null 2>&1; then
    if confirm "未检测到 ufw，是否现在安装?"; then
      echo -e "  正在安装 ufw..."
      apt update >/dev/null 2>&1
      if apt install -y ufw >/dev/null 2>&1; then
        echo -e "${GREEN}  ufw 安装完成${NC}"
      else
        echo -e "${RED}  ufw 安装失败，请检查网络后重试${NC}"
        read -p "  按回车返回..."
        return
      fi
    else
      echo "  已取消"
      read -p "  按回车返回..."
      return
    fi
  fi

  while true; do
    clear
    echo -e "${CYAN}────────── 防火墙管理 ──────────${NC}"
    echo ""
    echo -e "${YELLOW}-- 当前防火墙状态 --${NC}"
    if ufw status | grep -q "Status: active"; then
      # 禁 ping 需修改 before.rules 的 echo-request ACCEPT→DROP（ufw 默认先放行 ICMP，普通 deny 规则不生效）
      if grep -q -- '--icmp-type echo-request -j DROP' /etc/ufw/before.rules 2>/dev/null; then
        echo -e "   ${GREEN}已开启 (active)${NC}    Ping: ${YELLOW}禁止${NC}"
      else
        echo -e "   ${GREEN}已开启 (active)${NC}    Ping: ${GREEN}允许${NC}"
      fi
    else
      echo -e "   ${RED}未开启 (inactive)${NC}"
    fi
    echo ""
    echo -e "${YELLOW}-- 当前放行端口 --${NC}"
    rules=$(ufw status numbered 2>/dev/null | grep -E 'ALLOW|DENY|LIMIT|REJECT')
    if [ -n "$rules" ]; then
      echo "$rules"
    else
      echo "  (空)"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 放行 v4 端口"
    echo -e "   ${GREEN}2${NC}) 取消放行 v4 端口"
    echo -e "   ${GREEN}3${NC}) 放行 V6 端口"
    echo -e "   ${GREEN}4${NC}) 取消放行 V6 端口"
    echo -e "   ${GREEN}5${NC}) 开启防火墙"
    echo -e "   ${GREEN}6${NC}) 关闭防火墙"
    echo -e "   ${GREEN}7${NC}) 开关 Ping"
    echo -e "   ${GREEN}8${NC}) 重置默认策略"
    echo -e "   ${GREEN}9${NC}) 卸载防火墙"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  输入要放行的端口 (如 80、80/tcp、80/udp，输入0取消): " port
        if [ "$port" = "0" ]; then
          echo "  已取消"
        elif port_check "$port"; then
          fw_port v4 allow "$port" && echo -e "${GREEN}  已放行 v4 ${port}${NC}" || echo -e "${RED}  操作失败${NC}"
        else
          echo -e "${RED}  无效输入 (示例: 80 或 80/tcp 或 80/udp)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      2)
        read -p "  输入要取消的端口 (如 80、80/tcp、80/udp，输入0取消): " port
        if [ "$port" = "0" ]; then
          echo "  已取消"
        elif port_check "$port"; then
          fw_port v4 delete "$port" && echo -e "${GREEN}  已取消 v4 ${port}${NC}" || echo -e "${RED}  操作失败(可能未放行)${NC}"
        else
          echo -e "${RED}  无效输入 (示例: 80 或 80/tcp 或 80/udp)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      3)
        read -p "  输入要放行的端口 (如 80、80/tcp、80/udp，输入0取消): " port
        if [ "$port" = "0" ]; then
          echo "  已取消"
        elif port_check "$port"; then
          fw_port v6 allow "$port" && echo -e "${GREEN}  已放行 V6 ${port}${NC}" || echo -e "${RED}  操作失败${NC}"
        else
          echo -e "${RED}  无效输入 (示例: 80 或 80/tcp 或 80/udp)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      4)
        read -p "  输入要取消的端口 (如 80、80/tcp、80/udp，输入0取消): " port
        if [ "$port" = "0" ]; then
          echo "  已取消"
        elif port_check "$port"; then
          fw_port v6 delete "$port" && echo -e "${GREEN}  已取消 V6 ${port}${NC}" || echo -e "${RED}  操作失败(可能未放行)${NC}"
        else
          echo -e "${RED}  无效输入 (示例: 80 或 80/tcp 或 80/udp)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      5)
        if confirm "确认开启防火墙?"; then
          # 保护：无条件确保 v4 与 v6 的 22/tcp 都已放行，防止开启防火墙后锁死 SSH
          # 不做文本检测（ufw 输出格式因版本而异，易误判），直接执行；
          # ufw 对已存在的相同规则自动跳过 (Skipping adding existing rule)，幂等无副作用
          echo -e "${YELLOW}  确保 IPv4 22/tcp 已放行...${NC}"
          fw_port v4 allow 22/tcp
          echo -e "${YELLOW}  确保 IPv6 22/tcp 已放行...${NC}"
          fw_port v6 allow 22/tcp
          echo -e "${YELLOW}  开启防火墙中...${NC}"
          ufw --force enable
          echo -e "${GREEN}  防火墙已开启 (开机自启)${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      6)
        if confirm "确认关闭防火墙 (所有端口将暴露)?"; then
          echo -e "${YELLOW}  关闭防火墙中...${NC}"
          ufw disable
          echo -e "${YELLOW}  防火墙已关闭 (重启后仍保持关闭)${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      7)
        # 防火墙关闭时：提示需先开启才能控制 ping
        if ! ufw status | grep -q "Status: active"; then
          echo -e "${YELLOW}  防火墙目前关闭，允许 ping 或禁止 ping 需要开启防火墙${NC}"
          if confirm "是否先开启防火墙再继续?"; then
            echo -e "${YELLOW}  开启防火墙中...${NC}"
            ufw --force enable
            echo -e "${GREEN}  防火墙已开启${NC}"
          else
            echo "  已取消"
            read -p "  按回车继续..."
            continue
          fi
        fi
        # 清理旧版无效规则（普通 deny 规则不生效，避免状态显示混乱）
        ufw delete deny in proto icmp icmp-type echo-request >/dev/null 2>&1
        # 按当前状态切换（改 /etc/ufw/before.rules 的 echo-request ACCEPT/DROP，v4+v6）
        if grep -q -- '--icmp-type echo-request -j DROP' /etc/ufw/before.rules 2>/dev/null; then
          if confirm "当前 ping 已禁止，确认允许 ping?"; then
            if [ ! -f /etc/ufw/before.rules ]; then
              echo -e "${RED}  未找到 /etc/ufw/before.rules，无法切换 Ping${NC}"
            elif sed -i 's/\(--icmp-type echo-request -j \)DROP/\1ACCEPT/' /etc/ufw/before.rules 2>/dev/null && grep -q -- '--icmp-type echo-request -j ACCEPT' /etc/ufw/before.rules; then
              [ -f /etc/ufw/before6.rules ] && sed -i 's/\(--icmp-type echo-request -j \)DROP/\1ACCEPT/' /etc/ufw/before6.rules 2>/dev/null
              ufw reload >/dev/null 2>&1
              # 允许 ping 后备份已无意义，自动清理（零残留）
              rm -f /tmp/ufw-before*.bak.* 2>/dev/null
              echo -e "${GREEN}  已允许 ping${NC}"
            else
              echo -e "${RED}  修改 before.rules 失败，未生效${NC}"
            fi
          else
            echo "  已取消"
          fi
        else
          if confirm "当前 ping 已允许，确认禁止 ping?"; then
            if [ ! -f /etc/ufw/before.rules ]; then
              echo -e "${RED}  未找到 /etc/ufw/before.rules，无法切换 Ping${NC}"
            else
              # 备份到 /tmp（重启自动清理，不在 /etc/ufw 残留文件）
              cp /etc/ufw/before.rules /tmp/ufw-before.rules.bak.$SECONDS 2>/dev/null
              if sed -i 's/\(--icmp-type echo-request -j \)ACCEPT/\1DROP/' /etc/ufw/before.rules 2>/dev/null && grep -q -- '--icmp-type echo-request -j DROP' /etc/ufw/before.rules; then
                if [ -f /etc/ufw/before6.rules ]; then
                  cp /etc/ufw/before6.rules /tmp/ufw-before6.rules.bak.$SECONDS 2>/dev/null
                  sed -i 's/\(--icmp-type echo-request -j \)ACCEPT/\1DROP/' /etc/ufw/before6.rules 2>/dev/null
                fi
                ufw reload >/dev/null 2>&1
                echo -e "${GREEN}  已禁止 ping${NC}"
              else
                echo -e "${RED}  修改 before.rules 失败，未生效${NC}"
              fi
            fi
          else
            echo "  已取消"
          fi
        fi
        read -p "  按回车继续..."
        ;;
      8)
        if confirm "确认重置默认策略 (入站拒绝/出站允许)?"; then
          echo -e "${YELLOW}  重置默认策略为: 入站拒绝 / 出站允许${NC}"
          ufw default deny incoming
          ufw default allow outgoing
          # 重置时同时恢复 Ping 允许（echo-request 改回 ACCEPT，v4+v6）
          if [ ! -f /etc/ufw/before.rules ]; then
            echo -e "${RED}  未找到 /etc/ufw/before.rules，Ping 状态可能无法恢复${NC}"
          else
            sed -i 's/\(--icmp-type echo-request -j \)DROP/\1ACCEPT/' /etc/ufw/before.rules 2>/dev/null
            [ -f /etc/ufw/before6.rules ] && sed -i 's/\(--icmp-type echo-request -j \)DROP/\1ACCEPT/' /etc/ufw/before6.rules 2>/dev/null
          fi
          ufw reload >/dev/null 2>&1
          rm -f /tmp/ufw-before*.bak.* 2>/dev/null
          echo -e "${GREEN}  默认策略已重置 (进站全封，出站全开，Ping 已恢复允许)${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      9)
        echo -e "${RED}[!] 卸载防火墙将关闭 ufw 并删除全部配置，所有端口将暴露${NC}"
        echo -en "${YELLOW}  输入 yes 确认: ${NC}"
        read -r ans
        if [ "$ans" = "yes" ]; then
          echo -e "${YELLOW}  关闭防火墙...${NC}"
          ufw --force disable >/dev/null 2>&1
          echo -e "${YELLOW}  卸载 ufw 软件包并清除配置...${NC}"
          apt remove --purge -y ufw >/dev/null 2>&1
          rm -rf /etc/ufw /etc/default/ufw /var/log/ufw.log* 2>/dev/null
          echo -e "${GREEN}  防火墙已卸载，系统已恢复无防火墙状态 (iptables 默认放行)${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      0)
        return
        ;;
      *)
        ;;
    esac
  done
}

# ---------- 10. SOCKS5 代理 ----------
# 规范化代理目标：IPv6 地址自动加方括号 (IPv4/域名原样返回)
norm_proxy_host() {
  local t="$1"
  case "$t" in
    *:*)  # 含冒号 = IPv6，去掉已有方括号后统一加
      t="${t#[}"
      t="${t%]}"
      echo "[$t]"
      ;;
    *) echo "$t" ;;
  esac
}

sys_proxy() {
  local env_file="/tmp/proxy.sh"
  while true; do
    clear
    echo -e "${CYAN}────────── SOCKS5 ──────────${NC}"
    echo ""
    # 显示当前状态
    unset ALL_PROXY all_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    if [ -f "$env_file" ]; then
      source "$env_file"
      if [ -n "$ALL_PROXY" ]; then
        echo -e "  当前状态: ${GREEN}已启用 (临时，重启后失效)${NC}"
        echo -e "  代理类型: ${ALL_PROXY%%://*}"
        # 地址脱敏：user:pass@ → ***@，避免泄露密码
        local proxy_disp
        proxy_disp=$(printf '%s' "${ALL_PROXY#*://}" | sed 's#[^/@]*@#***@#')
        echo -e "  代理地址: $proxy_disp"
        # 测试连接
        echo -e "  正在检测代理连接...${NC}"
        local_ip=$(curl -s --connect-timeout 5 https://myip.ipip.net 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        if [ -n "$local_ip" ]; then
          echo -e "  出口 IP: ${GREEN}${local_ip}${NC}"
        else
          echo -e "  出口 IP: ${RED}无法连接${NC}"
        fi
      else
        echo -e "  当前状态: ${YELLOW}未启用${NC}"
      fi
    else
      echo -e "  当前状态: ${YELLOW}未启用${NC}"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) SOCKS5 代理"
    echo -e "   ${GREEN}2${NC}) HTTP 代理"
    echo -e "   ${GREEN}3${NC}) 取消代理"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  输入代理 IP 或域名: " proxy_ip
        read -p "  输入代理端口 (1-65535，如 1080): " proxy_port
        # 用户名密码 (无认证直接回车跳过)
        read -p "  输入代理用户名 (无认证直接回车): " proxy_user
        proxy_pass=""
        if [ -n "$proxy_user" ]; then
          read -p "  输入代理密码 (留空则无密码): " proxy_pass
        fi
        # 校验端口
        if ! echo "$proxy_port" | grep -qE '^[0-9]+$' || [ "$proxy_port" -lt 1 ] || [ "$proxy_port" -gt 65535 ]; then
          echo -e "${RED}  端口无效 (必须是 1-65535 的数字)${NC}"
          read -p "  按回车继续..."
        # 校验 IP/域名 (允许 IPv4/IPv6/域名，IPv6 可带方括号；用 tr 过滤非法字符)
        elif [ -n "$(printf '%s' "$proxy_ip" | tr -d 'a-zA-Z0-9.:[]-')" ]; then
          echo -e "${RED}  IP/域名格式无效${NC}"
          read -p "  按回车继续..."
        # 校验用户名密码不含 URL 特殊字符 (@ : / 空格等)
        elif [ -n "$proxy_user" ] && ! echo "${proxy_user}${proxy_pass}" | grep -qE '^[a-zA-Z0-9._%-]*$'; then
          echo -e "${RED}  用户名/密码包含非法字符 (@ : / 空格等)${NC}"
          read -p "  按回车继续..."
        else
          proxy_host=$(norm_proxy_host "$proxy_ip")
          if [ -n "$proxy_user" ]; then
            proxy_url="socks5://${proxy_user}:${proxy_pass}@${proxy_host}:${proxy_port}"
            proxy_disp="socks5://${proxy_user}:***@${proxy_host}:${proxy_port}"
          else
            proxy_url="socks5://${proxy_host}:${proxy_port}"
            proxy_disp="$proxy_url"
          fi
          echo -e "${YELLOW}  正在测试代理连接...${NC}"
          curl -x "$proxy_url" -s --connect-timeout 5 https://www.baidu.com >/dev/null 2>&1
          curl_ret=$?
          if [ "$curl_ret" -eq 0 ]; then
            cat > "$env_file" << EOF
export http_proxy="$proxy_url"
export https_proxy="$proxy_url"
export all_proxy="$proxy_url"
export HTTP_PROXY="$proxy_url"
export HTTPS_PROXY="$proxy_url"
export ALL_PROXY="$proxy_url"
EOF
            echo -e "${GREEN}  代理连接成功，已保存${NC}"
            echo -e "${GREEN}  SOCKS5 代理已设置: $proxy_disp${NC}"
            echo -e "${YELLOW}  临时生效，重启后自动失效${NC}"
            echo -e "${YELLOW}  当前终端执行: source $env_file${NC}"
          else
            echo -e "${RED}  代理连接失败 (错误码: $curl_ret)，未保存${NC}"
            echo -e "${RED}  请检查 IP、端口、用户名密码是否正确，代理是否已启动${NC}"
          fi
          read -p "  按回车继续..."
        fi
        ;;
      2)
        read -p "  输入代理 IP 或域名: " proxy_ip
        read -p "  输入代理端口 (1-65535，如 7890): " proxy_port
        # 用户名密码 (无认证直接回车跳过)
        read -p "  输入代理用户名 (无认证直接回车): " proxy_user
        proxy_pass=""
        if [ -n "$proxy_user" ]; then
          read -p "  输入代理密码 (留空则无密码): " proxy_pass
        fi
        # 校验端口
        if ! echo "$proxy_port" | grep -qE '^[0-9]+$' || [ "$proxy_port" -lt 1 ] || [ "$proxy_port" -gt 65535 ]; then
          echo -e "${RED}  端口无效 (必须是 1-65535 的数字)${NC}"
          read -p "  按回车继续..."
        # 校验 IP/域名 (允许 IPv4/IPv6/域名，IPv6 可带方括号；用 tr 过滤非法字符)
        elif [ -n "$(printf '%s' "$proxy_ip" | tr -d 'a-zA-Z0-9.:[]-')" ]; then
          echo -e "${RED}  IP/域名格式无效${NC}"
          read -p "  按回车继续..."
        # 校验用户名密码不含 URL 特殊字符 (@ : / 空格等)
        elif [ -n "$proxy_user" ] && ! echo "${proxy_user}${proxy_pass}" | grep -qE '^[a-zA-Z0-9._%-]*$'; then
          echo -e "${RED}  用户名/密码包含非法字符 (@ : / 空格等)${NC}"
          read -p "  按回车继续..."
        else
          proxy_host=$(norm_proxy_host "$proxy_ip")
          if [ -n "$proxy_user" ]; then
            proxy_url="http://${proxy_user}:${proxy_pass}@${proxy_host}:${proxy_port}"
            proxy_disp="http://${proxy_user}:***@${proxy_host}:${proxy_port}"
          else
            proxy_url="http://${proxy_host}:${proxy_port}"
            proxy_disp="$proxy_url"
          fi
          echo -e "${YELLOW}  正在测试代理连接...${NC}"
          curl -x "$proxy_url" -s --connect-timeout 5 https://www.baidu.com >/dev/null 2>&1
          curl_ret=$?
          if [ "$curl_ret" -eq 0 ]; then
            cat > "$env_file" << EOF
export http_proxy="$proxy_url"
export https_proxy="$proxy_url"
export all_proxy="$proxy_url"
export HTTP_PROXY="$proxy_url"
export HTTPS_PROXY="$proxy_url"
export ALL_PROXY="$proxy_url"
EOF
            echo -e "${GREEN}  代理连接成功，已保存${NC}"
            echo -e "${GREEN}  HTTP 代理已设置: $proxy_disp${NC}"
            echo -e "${YELLOW}  临时生效，重启后自动失效${NC}"
            echo -e "${YELLOW}  当前终端执行: source $env_file${NC}"
          else
            echo -e "${RED}  代理连接失败 (错误码: $curl_ret)，未保存${NC}"
            echo -e "${RED}  请检查 IP、端口、用户名密码是否正确，代理是否已启动${NC}"
          fi
          read -p "  按回车继续..."
        fi
        ;;
      3)
        if confirm "确认取消代理?"; then
          rm -f "$env_file"
          unset ALL_PROXY all_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
          echo -e "${GREEN}  代理已取消${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 8. 记事本 ----------
# 记事本文件跟着脚本所在目录走，放哪都能跑
NOTES_FILE="$(dirname "$(readlink -f "$0")")/notes.txt"

sys_notes() {
  # 首次进入：文件不存在时询问是否创建
  if [ ! -f "$NOTES_FILE" ]; then
    clear
    echo -e "${CYAN}────────── 记事本 ──────────${NC}"
    echo ""
    echo -e "  笔记文件不存在，将创建在: ${GREEN}${NOTES_FILE}${NC}"
    echo ""
    if ! confirm "是否创建笔记文件?"; then
      echo "  已取消"
      return
    fi
    cat > "$NOTES_FILE" << 'AD'
低价国际大带宽VPS ↓ ↓ ↓复制整段浏览器访问
https://akile.ai/shop/server?type=traffic&areaId=3&nodeId=1&planId=811&aff_code=fcce7cc7-f708-489a-8d35-4a5c8fb015bb
（输入3再输入0删掉烦人的小广告
AD
  fi
  while true; do
    clear
    echo -e "${CYAN}────────── 记事本 ──────────${NC}"
    echo -e "  文件位置: ${GREEN}${NOTES_FILE}${NC}"
    echo ""
    # 显示现有笔记
    if [ -s "$NOTES_FILE" ]; then
      awk '{printf "  %d) %s\n", NR, $0}' "$NOTES_FILE"
    else
      echo "  (空)"
    fi
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 创建行"
    echo -e "   ${GREEN}2${NC}) 编辑行"
    echo -e "   ${GREEN}3${NC}) 删除行"
    echo -e "   ${GREEN}4${NC}) 删除笔记文件"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        echo "" >> "$NOTES_FILE"
        ;;
      2)
        read -p "  行号+空格+内容: " input
        num=$(echo "$input" | awk '{print $1}')
        content=$(echo "$input" | cut -d' ' -f2-)
        total=$(awk 'END{print NR}' "$NOTES_FILE" 2>/dev/null || echo 0)
        if echo "$num" | grep -qE '^[0-9]+$' && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
          sed -i "${num}c\\${content}" "$NOTES_FILE"
        else
          echo -e "${RED}  无效行号 (1-${total})${NC}"
          read -p "  按回车继续..."
        fi
        ;;
      3)
        read -p "  行号 (0=清空所有): " num
        total=$(awk 'END{print NR}' "$NOTES_FILE" 2>/dev/null || echo 0)
        if [ "$num" = "0" ]; then
          if [ "$total" -eq 0 ]; then
            echo -e "${YELLOW}  记事本已经是空的${NC}"
            read -p "  按回车继续..."
          elif confirm "确认清空所有笔记 (共 ${total} 行)?"; then
            > "$NOTES_FILE"
          else
            echo "  已取消"
            read -p "  按回车继续..."
          fi
        elif echo "$num" | grep -qE '^[0-9]+$' && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
          sed -i "${num}d" "$NOTES_FILE"
        else
          echo -e "${RED}  无效行号 (0-${total})${NC}"
          read -p "  按回车继续..."
        fi
        ;;
      4)
        if confirm "确认删除整个笔记文件? (所有笔记将丢失)"; then
          rm -f "$NOTES_FILE"
          echo -e "${GREEN}  笔记文件已删除${NC}"
          read -p "  按回车返回..."
          return
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

# ---------- 2. 系统日志 ----------
sys_logs() {
  clear
  echo -e "${CYAN}────────── 系统日志 (最近20条) ──────────${NC}"
  journalctl -n 20 --no-pager 2>/dev/null | tail -20
  echo ""
  read -p "  按回车返回菜单..."
}

# ---------- 7. 文件管理 ----------
sys_files() {
  local cur="/"
  local -a items
  while true; do
    clear
    echo -e "${CYAN}────────── 文件管理 ──────────${NC}"
    echo -e "  当前目录: ${GREEN}${cur}${NC}"
    echo ""
    items=()
    local i=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      f="${f%/}"
      i=$((i+1))
      items[$i]="$f"
      echo -e "   ${GREEN}$i${NC}) ${BLUE}[文件夹]${NC} $f/"
    done < <(ls -Ap1 "$cur" 2>/dev/null | grep '/$' | sort)
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      i=$((i+1))
      items[$i]="$f"
      local sz=$(ls -lh "$cur/$f" 2>/dev/null | awk '{print $5}')
      echo -e "   ${GREEN}$i${NC}) $f  ${YELLOW}(${sz})${NC}"
    done < <(ls -Ap1 "$cur" 2>/dev/null | grep -v '/$' | sort)
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}0${NC}) 返回上级目录"
    echo -e "   ${GREEN}n${NC}) 新建文件夹"
    echo -e "   ${GREEN}q${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  输入序号操作: " sel
    case "$sel" in
      q) return ;;
      0)
        if [ "$cur" = "/" ]; then
          return
        else
          cur=$(dirname "$cur")
        fi
        ;;
      n)
        read -p "  输入新文件夹名: " fname
        if [ -n "$fname" ]; then
          if echo "$fname" | grep -qE '[ /\\;|&`$]'; then
            echo -e "${RED}  文件夹名不能含空格或特殊字符${NC}"
          elif mkdir "$cur/$fname" 2>/dev/null; then
            echo -e "${GREEN}  已创建: $fname${NC}"
          else
            echo -e "${RED}  创建失败${NC}"
          fi
          read -p "  按回车继续..."
        fi
        ;;
      *)
        if echo "$sel" | grep -qE '^[0-9]+$' && [ "$sel" -ge 1 ] && [ "$sel" -le "$i" ]; then
          local f="${items[$sel]}"
          local fpath="$cur/$f"
          if [ -d "$fpath" ]; then
            cur="$fpath"
          else
            # 判断是否压缩包
            local is_archive=0
            case "$f" in
              *.tar.gz|*.tgz|*.tar.bz2|*.tar.xz|*.gz|*.bz2|*.xz|*.zip|*.7z|*.rar) is_archive=1 ;;
            esac
            # 文件操作
            while true; do
              clear
              echo -e "${CYAN}── 文件: $f ──${NC}"
              echo -e "  路径: $fpath"
              echo "  ──────────────────────────────────────"
              echo -e "   ${GREEN}1${NC}) 查看内容"
              echo -e "   ${GREEN}2${NC}) 删除文件"
              echo -e "   ${GREEN}3${NC}) 重命名"
              echo -e "   ${GREEN}4${NC}) 复制文件"
              echo -e "   ${GREEN}5${NC}) 移动文件"
              echo -e "   ${GREEN}6${NC}) 压缩文件"
              echo -e "   ${GREEN}7${NC}) 改权限"
              if [ "$is_archive" = "1" ]; then
                echo -e "   ${GREEN}8${NC}) 解压到当前目录"
              fi
              echo -e "   ${GREEN}0${NC}) 返回"
              echo "  ──────────────────────────────────────"
              read -p "  请输入选项: " fop
              case "$fop" in
                1)
                  clear
                  echo -e "${CYAN}── $f (前100行) ──${NC}"
                  head -100 "$fpath" 2>/dev/null || echo -e "${RED}  无法读取 (二进制文件?)${NC}"
                  echo ""
                  read -p "  按回车继续..."
                  ;;
                2)
                  # 检测是否在系统关键目录下
                  local is_system=0
                  case "$fpath" in
                    /bin/*|/sbin/*|/etc/*|/usr/*|/lib/*|/lib64/*|/boot/*|/dev/*|/proc/*|/sys/*|/var/*)
                      is_system=1
                      ;;
                    /bin|/sbin|/etc|/usr|/lib|/lib64|/boot|/dev|/proc|/sys|/var)
                      is_system=1
                      ;;
                  esac
                  if [ "$is_system" = "1" ]; then
                    echo -e "${RED}[!] 警告：这是系统目录下的文件，删除可能导致系统异常！${NC}"
                  fi
                  if confirm "确认删除 $f ?"; then
                    rm -rf "$fpath" && echo -e "${GREEN}  已删除${NC}" || echo -e "${RED}  删除失败${NC}"
                  else
                    echo "  已取消"
                  fi
                  read -p "  按回车继续..."
                  break
                  ;;
                3)
                  echo -e "  输入新文件名 ${YELLOW}(需含后缀，不能含空格)${NC}"
                  read -p "  新文件名: " newname
                  if [ -n "$newname" ]; then
                    if echo "$newname" | grep -qE '[ /\\;|&`$]'; then
                      echo -e "${RED}  文件名不能含空格或特殊字符${NC}"
                    elif mv "$fpath" "$cur/$newname" 2>/dev/null; then
                      echo -e "${GREEN}  已重命名为: $newname${NC}"
                      f="$newname"
                      fpath="$cur/$newname"
                    else
                      echo -e "${RED}  重命名失败${NC}"
                    fi
                  fi
                  read -p "  按回车继续..."
                  ;;
                4)
                  read -p "  复制到 (目录): " target
                  if [ -n "$target" ]; then
                    [ "${target: -1}" != "/" ] && target="$target/"
                    if [ ! -d "$target" ]; then
                      echo -e "${RED}  目录不存在: $target${NC}"
                    elif [ "$target" = "$cur/" ]; then
                      echo -e "${YELLOW}  目标就是当前目录${NC}"
                    elif cp "$fpath" "$target" 2>/dev/null; then
                      echo -e "${GREEN}  已复制到: $target$f${NC}"
                    else
                      echo -e "${RED}  复制失败 (同名文件已存在?)${NC}"
                    fi
                  fi
                  read -p "  按回车继续..."
                  ;;
                5)
                  read -p "  移动到 (目录): " target
                  if [ -n "$target" ]; then
                    [ "${target: -1}" != "/" ] && target="$target/"
                    if [ ! -d "$target" ]; then
                      echo -e "${RED}  目录不存在: $target${NC}"
                    elif [ "$target" = "$cur/" ]; then
                      echo -e "${YELLOW}  目标就是当前目录${NC}"
                    elif mv "$fpath" "$target" 2>/dev/null; then
                      echo -e "${GREEN}  已移动到: $target$f${NC}"
                      read -p "  按回车继续..."
                      break
                    else
                      echo -e "${RED}  移动失败 (同名文件已存在?)${NC}"
                    fi
                  fi
                  read -p "  按回车继续..."
                  ;;
                6)
                  archname="${f}.tar.gz"
                  echo -e "  默认压缩: ${GREEN}tar.gz${NC} ${YELLOW}(回车确认)${NC}"
                  echo -e "  或输入新名 ${YELLOW}(支持 .zip .7z .tar.gz 等)${NC}"
                  read -p "  自定义: " custom
                  [ -n "$custom" ] && archname="$custom"
                  # 检查文件名是否含空格
                  if echo "$archname" | grep -q ' '; then
                    echo -e "${RED}  文件名不能含空格${NC}"
                    read -p "  按回车继续..."
                    break
                  fi
                  case "$archname" in
                    *.zip)
                      if ! command -v zip >/dev/null 2>&1; then
                        if confirm "未安装 zip，是否现在安装?"; then
                          apt install -y zip >/dev/null 2>&1 && echo -e "${GREEN}  zip 安装完成${NC}" || echo -e "${RED}  安装失败${NC}"
                        else
                          echo "  已取消"
                          read -p "  按回车继续..."
                          break
                        fi
                      fi
                      zip -j "$cur/$archname" "$cur/$f" && echo -e "${GREEN}  已压缩为: $archname${NC}" || echo -e "${RED}  压缩失败${NC}"
                      ;;
                    *.7z)
                      if ! command -v 7z >/dev/null 2>&1; then
                        if confirm "未安装 7z，是否现在安装 p7zip-full?"; then
                          apt install -y p7zip-full >/dev/null 2>&1 && echo -e "${GREEN}  7z 安装完成${NC}" || echo -e "${RED}  安装失败${NC}"
                        else
                          echo "  已取消"
                          read -p "  按回车继续..."
                          break
                        fi
                      fi
                      7z a "$cur/$archname" "$cur/$f" && echo -e "${GREEN}  已压缩为: $archname${NC}" || echo -e "${RED}  压缩失败${NC}"
                      ;;
                    *)
                      if tar czf "$cur/$archname" -C "$cur" "$f"; then
                        echo -e "${GREEN}  已压缩为: $archname${NC}"
                      else
                        echo -e "${RED}  压缩失败${NC}"
                      fi
                      ;;
                  esac
                  read -p "  按回车继续..."
                  break
                  ;;
                7)
                  cur_perm=$(stat -c '%a' "$fpath" 2>/dev/null)
                  echo -e "  当前权限: ${GREEN}$cur_perm${NC}"
                  read -p "  输入新权限 (如 755/644): " perm
                  if echo "$perm" | grep -qE '^[0-7]{3,4}$'; then
                    if [ "$perm" = "777" ]; then
                      if confirm "777 不安全，确认继续?"; then
                        chmod "$perm" "$fpath" 2>/dev/null && echo -e "${YELLOW}  权限已改为: $perm (不安全)${NC}" || echo -e "${RED}  修改失败${NC}"
                      else
                        echo "  已取消"
                      fi
                    else
                      chmod "$perm" "$fpath" 2>/dev/null && echo -e "${GREEN}  权限已改为: $perm${NC}" || echo -e "${RED}  修改失败${NC}"
                    fi
                  else
                    echo -e "${RED}  无效权限 (如 755)${NC}"
                  fi
                  read -p "  按回车继续..."
                  ;;
                8)
                  if [ "$is_archive" = "1" ]; then
                    case "$f" in
                      *.tar.gz|*.tgz)
                        tar xzf "$fpath" -C "$cur" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.tar.bz2)
                        tar xjf "$fpath" -C "$cur" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.tar.xz)
                        tar xJf "$fpath" -C "$cur" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.gz)
                        gunzip -k "$fpath" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.bz2)
                        bunzip2 -k "$fpath" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.xz)
                        unxz -k "$fpath" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.zip)
                        if ! command -v unzip >/dev/null 2>&1; then
                          if confirm "未安装 unzip，是否现在安装?"; then
                            apt install -y unzip >/dev/null 2>&1 && echo -e "${GREEN}  unzip 安装完成${NC}" || echo -e "${RED}  安装失败${NC}"
                          else
                            echo "  已取消"
                          fi
                          read -p "  按回车继续..."
                          break
                        fi
                        unzip -o "$fpath" -d "$cur" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.7z)
                        if ! command -v 7z >/dev/null 2>&1; then
                          if confirm "未安装 7z，是否现在安装 p7zip-full?"; then
                            apt install -y p7zip-full >/dev/null 2>&1 && echo -e "${GREEN}  7z 安装完成${NC}" || echo -e "${RED}  安装失败${NC}"
                          else
                            echo "  已取消"
                          fi
                          read -p "  按回车继续..."
                          break
                        fi
                        7z x "$fpath" -o"$cur" -y && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                      *.rar)
                        if ! command -v unrar >/dev/null 2>&1; then
                          if confirm "未安装 unrar，是否现在安装?"; then
                            apt install -y unrar >/dev/null 2>&1 && echo -e "${GREEN}  unrar 安装完成${NC}" || echo -e "${RED}  安装失败${NC}"
                          else
                            echo "  已取消"
                          fi
                          read -p "  按回车继续..."
                          break
                        fi
                        unrar x "$fpath" "$cur" && echo -e "${GREEN}  解压完成${NC}" || echo -e "${RED}  解压失败${NC}"
                        ;;
                    esac
                    read -p "  按回车继续..."
                    break
                  fi
                  ;;
                0) break ;;
                *) ;;
              esac
            done
          fi
        else
          echo -e "${RED}  无效输入${NC}"
          read -p "  按回车继续..."
        fi
        ;;
    esac
  done
}

# ---------- 8. 软件管理 ----------
sys_packages() {
  local -a pkgs
  local filter=""
  while true; do
    clear
    echo -e "${CYAN}────────── 软件管理 ──────────${NC}"
    [ -n "$filter" ] && echo -e "  搜索: ${YELLOW}$filter${NC}"
    echo ""
    pkgs=()
    local i=0
    while IFS= read -r name ver; do
      [ -z "$name" ] && continue
      i=$((i+1))
      pkgs[$i]="$name $ver"
      echo -e "   ${GREEN}$i${NC}) $name  ${YELLOW}$ver${NC}"
    done < <(dpkg-query -W -f='${Package} ${Version}\n' 2>/dev/null | grep -i "$filter" | sort)
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}s${NC}) 搜索包名"
    echo -e "   ${GREEN}0${NC}) 返回"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  输入序号查看详情: " sel
    case "$sel" in
      0)
        if [ -n "$filter" ]; then
          filter=""
        else
          return
        fi
        ;;
      s)
        read -p "  输入搜索关键词: " filter
        ;;
      *)
        if echo "$sel" | grep -qE '^[0-9]+$' && [ "$sel" -ge 1 ] && [ "$sel" -le "$i" ]; then
          local pkgname=$(echo "${pkgs[$sel]}" | awk '{print $1}')
          while true; do
            clear
            echo -e "${CYAN}── 包详情: $pkgname ──${NC}"
            echo ""
            dpkg-query -s "$pkgname" 2>/dev/null | grep -E '^(Package|Version|Installed-Size|Description):' | head -10
            echo ""
            echo -e "  安装的文件数: $(dpkg-query -L "$pkgname" 2>/dev/null | wc -l)"
            echo ""
            echo "  ──────────────────────────────────────"
            echo -e "   ${GREEN}1${NC}) 卸载此包"
            echo -e "   ${GREEN}0${NC}) 返回列表"
            echo "  ──────────────────────────────────────"
            echo ""
            read -p "  请输入选项: " pop
            case "$pop" in
              1)
                # 系统关键包禁止卸载
                case "$pkgname" in
                  apt|bash|libc6|systemd|dpkg|debian-archive-keyring|debian-base|debianutils|initscripts|libapt-pkg|libgcc|libstdc|login|mount|passwd|perl-base|rootskel|sysvinit|tar|udev|util-linux|x-ui|xray|3x-ui)
                    echo -e "${RED}[!] 警告：这是系统/面板关键包，卸载可能导致系统崩溃！${NC}"
                    echo -e "${YELLOW}    输入 yes 确认继续，其他任意键取消:${NC}"
                    read -p "  输入 yes: " double
                    if [ "$double" = "yes" ]; then
                      apt remove -y "$pkgname" >/dev/null 2>&1 && echo -e "${GREEN}  已卸载${NC}" || echo -e "${RED}  卸载失败${NC}"
                    else
                      echo "  已取消"
                    fi
                    read -p "  按回车继续..."
                    break
                    ;;
                  *)
                    if confirm "确认卸载 $pkgname ?"; then
                      apt remove -y "$pkgname" >/dev/null 2>&1 && echo -e "${GREEN}  已卸载${NC}" || echo -e "${RED}  卸载失败${NC}"
                    else
                      echo "  已取消"
                    fi
                    read -p "  按回车继续..."
                    break
                    ;;
                esac
                ;;
              0) break ;;
              *) ;;
            esac
          done
        fi
        ;;
    esac
  done
}

# 流媒体检测辅助: $1=平台名 $2=URL $3=CN重定向检查(1/0) $4=地区不支持关键词(可空)
# 检测完实时输出单行结果（配合 media_print），不累积
# 单次请求 + 收紧超时，避免拖慢小机型；仅需状态码的平台零内容下载
# 流媒体/AI 检测结果实时输出：清除"正在加载"行 → 打印结果 → 重新显示"正在加载"
media_print() {
  printf '\r\033[K'
  echo -e "  $1: $2"
  echo -en "${YELLOW}  正在加载...${NC}"
}

media_check() {
  local name="$1" url="$2" cnchk="$3" unavail="$4"
  local ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
  local code="" html=""
  # 全局期限保护：整组检测限时，到期未测项快速跳过（防个别接口异常拖死整个模块）
  if [ -n "$NET_DEADLINE" ] && [ "$SECONDS" -ge "$NET_DEADLINE" ]; then
    media_print "$name" "${YELLOW}超时跳过${NC}"
    return
  fi
  if [ "$cnchk" = "1" ] || [ -n "$unavail" ]; then
    # 需要页面内容判断：一次请求同时拿状态码和内容（限制 1MB，防内存占用）
    local out
    out=$(curl -sL --noproxy '*' --compressed --max-filesize 1000000 --connect-timeout 3 --max-time 5 \
      -A "$ua" -H "Accept-Language: en-US,en;q=0.9" -w $'\n%{http_code}' "$url" 2>/dev/null)
    code=$(printf '%s' "$out" | tail -1 | tr -d '\r')
    html=${out%$'\n'*}
  else
    # 只需状态码：零内容下载，最省 CPU/内存
    code=$(curl -sL --noproxy '*' --compressed --connect-timeout 3 --max-time 5 -o /dev/null -w "%{http_code}" \
      -A "$ua" -H "Accept-Language: en-US,en;q=0.9" "$url" 2>/dev/null)
  fi
  [ -z "$code" ] && code="000"
  case "$code" in
    000)
      media_print "$name" "${RED}无法访问${NC}"
      ;;
    200|201|202|204|301|302|303|307|308)
      if [ -n "$html" ]; then
        if [ "$cnchk" = "1" ] && echo "$html" | grep -q "www.google.cn"; then
          media_print "$name" "${YELLOW}CN (被重定向)${NC}"
          return
        fi
        if [ -n "$unavail" ] && echo "$html" | grep -qi "$unavail"; then
          media_print "$name" "${YELLOW}地区不支持${NC}"
          return
        fi
      fi
      media_print "$name" "${GREEN}可访问${NC}"
      ;;
    403)
      media_print "$name" "${YELLOW}被拦截 (HTTP 403)${NC}"
      ;;
    *)
      media_print "$name" "${RED}不可访问 (HTTP $code)${NC}"
      ;;
  esac
}

# ---------- 2. 网络状态 ----------
# 获取本机公网 IP：ip-api.com 优先（可同时拿地理位置），失败则多接口轮询兜底，任一成功即返回
# 成功时 PUB_IP=出口IP，PUB_GEO=地理位置 JSON（尽力而为）
get_pub_ip() {
  PUB_IP=""; PUB_GEO=""
  local api start
  start=$SECONDS
  PUB_GEO=$(curl -s --noproxy '*' --connect-timeout 3 --max-time 6 "http://ip-api.com/json/?lang=zh-CN&fields=status,query,country,city,isp,org,as" 2>/dev/null)
  if echo "$PUB_GEO" | grep -q '"status":"success"'; then
    PUB_IP=$(echo "$PUB_GEO" | grep -oE '"query":"[^"]*"' | cut -d'"' -f4)
    return 0
  fi
  # 兜底：https 多接口轮询（防 http 出站被限制），任一成功即返回；总时长上限 15 秒防卡死
  for api in "https://api.ipify.org" "https://icanhazip.com" "https://ipinfo.io/ip" "https://ip.sb" "https://api.ip.sb/ip" "https://ifconfig.me/ip" "https://ipv4.icanhazip.com" "https://myip.ipip.net"; do
    [ $((SECONDS - start)) -ge 15 ] && break
    PUB_IP=$(curl -s --noproxy '*' --connect-timeout 3 --max-time 5 "$api" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    [ -n "$PUB_IP" ] && break
  done
  if [ -n "$PUB_IP" ]; then
    PUB_GEO=$(curl -s --noproxy '*' --connect-timeout 3 --max-time 5 "http://ip-api.com/json/${PUB_IP}?lang=zh-CN&fields=status,query,country,city,isp,org,as" 2>/dev/null)
  fi
}

# 获取出口 IPv6：仅走 IPv6 出站 (-6 强制)，9 接口轮询；机器无 IPv6 时连接失败自然返回空
get_pub_ip6() {
  PUB_IP6=""
  local api start
  start=$SECONDS
  for api in "https://api6.ipify.org" "https://ipv6.icanhazip.com" "https://ifconfig.co" \
    "https://6.ipinfo.io" "https://v6.ident.me" "https://ipv6-test.com/api/myip.php" \
    "https://ifconfig.me/ip" "https://ip6.seeip.org" "https://api.ip.sb/ip"; do
    [ $((SECONDS - start)) -ge 10 ] && break
    PUB_IP6=$(curl -6 -s --noproxy '*' --connect-timeout 3 --max-time 5 "$api" 2>/dev/null | grep -oE '([0-9a-fA-F]{0,4}:){2,}[0-9a-fA-F:]+' | head -1 | tr -d '\r')
    [ -n "$PUB_IP6" ] && break
  done
}

# 出口 IP 检测 (多接口轮询，任一成功即返回，避免单接口失效)
sys_net() {
  clear
  echo -e "${CYAN}────────── 网络状态 ──────────${NC}"
  echo ""
  echo -e "${YELLOW}-- IP 信息 --${NC}"
  echo -en "${YELLOW}  正在加载...${NC}"
  local ip="" geo=""
  get_pub_ip
  ip="$PUB_IP"; geo="$PUB_GEO"
  # 清除"正在加载"提示行
  printf '\r\033[K'
  if [ -z "$ip" ]; then
    echo -e "${RED}  获取出口 IPv4 失败，请检查网络${NC}"
    read -p "  按回车返回主菜单..."
    return
  fi
  echo -e "  出口 IPv4: ${GREEN}$ip${NC}"
  # 出口 IPv6 (仅走 IPv6 出站接口，无 IPv6 时自然跳过)
  local ip6
  get_pub_ip6
  ip6="$PUB_IP6"
  [ -n "$ip6" ] && echo -e "  出口 IPv6: ${GREEN}$ip6${NC}"
  # 地理位置与 ISP 解析
  local country city isp org asn
  country=$(echo "$geo" | grep -oE '"country":"[^"]*"' | cut -d'"' -f4)
  city=$(echo "$geo" | grep -oE '"city":"[^"]*"' | cut -d'"' -f4)
  isp=$(echo "$geo" | grep -oE '"isp":"[^"]*"' | cut -d'"' -f4)
  org=$(echo "$geo" | grep -oE '"org":"[^"]*"' | cut -d'"' -f4)
  asn=$(echo "$geo" | grep -oE '"as":"[^"]*"' | cut -d'"' -f4)
  [ -n "$country" ] && echo "  国家: $country"
  [ -n "$city" ] && echo "  城市: $city"
  [ -n "$isp" ] && echo "  ISP: $isp"
  [ -n "$org" ] && echo "  组织: $org"
  [ -n "$asn" ] && echo "  ASN: $asn"
  # 流媒体检测（整组限时 20 秒，超时项跳过，检测出一个显示一个）
  echo ""
  echo -e "${YELLOW}-- 流媒体 --${NC}"
  echo -en "${YELLOW}  正在加载...${NC}"
  NET_DEADLINE=$((SECONDS + 20))
  media_check "YouTube" "https://www.youtube.com/premium" 1 ""
  media_check "Netflix" "https://www.netflix.com/title/80018499" 0 "not available in your"
  media_check "TikTok" "https://www.tiktok.com/" 0 ""
  media_check "Spotify" "https://open.spotify.com/" 0 ""
  media_check "Apple TV+" "https://tv.apple.com/" 0 ""
  media_check "Disney+" "https://www.disneyplus.com/" 0 ""
  media_check "Amazon Prime" "https://www.primevideo.com/" 0 ""
  # 清除最后一行"正在加载"提示
  printf '\r\033[K'
  echo ""
  # AI 检测（整组限时 18 秒，超时项跳过，检测出一个显示一个）
  echo -e "${YELLOW}-- AI --${NC}"
  echo -en "${YELLOW}  正在加载...${NC}"
  NET_DEADLINE=$((SECONDS + 18))
  media_check "ChatGPT" "https://chatgpt.com" 0 ""
  media_check "Claude" "https://claude.ai" 0 ""
  media_check "Gemini" "https://gemini.google.com" 0 ""
  media_check "Grok" "https://grok.com" 0 ""
  media_check "DeepSeek" "https://chat.deepseek.com" 0 ""
  media_check "豆包" "https://www.doubao.com" 0 ""
  # 清除最后一行"正在加载"提示
  printf '\r\033[K'
  echo ""
  read -p "  按回车返回主菜单..."
}

# ---------- 12. Ping 测试 ----------
# 检测结果页共用菜单：显示选项并处理选择，选 0 返回主菜单
# 双层循环：菜单只显示一次，无效输入原地提示不堆叠，检测完自动重显菜单
ping_action() {
  local choice
  while true; do
    # 清空检测期间积压的键盘输入，防止误触发下个选项
    if [ -t 0 ]; then
      while read -r -t 0; do read -r; done 2>/dev/null
    fi
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) IPv4 Ping"
    echo -e "   ${GREEN}2${NC}) IPv6 Ping"
    echo -e "   ${GREEN}3${NC}) IPv4 丢包测试"
    echo -e "   ${GREEN}4${NC}) IPv6 丢包测试"
    echo -e "   ${GREEN}5${NC}) 自定义 Ping"
    echo -e "   ${GREEN}6${NC}) 自定义丢包测试"
    echo -e "   ${GREEN}7${NC}) Globalping"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    while true; do
      read -p "  请输入选项: " choice
      case "$choice" in
        1) ping_both4; break ;;
        2) ping_both6; break ;;
        3) loss_both4; break ;;
        4) loss_both6; break ;;
        5) ping_custom; break ;;
        6) ping_custom_loss; break ;;
        7) ping_global; break ;;
        0) return 0 ;;
        *) echo -e "${RED}  无效选项，请重新输入${NC}" ;;
      esac
    done
  done
}

# 国内 Ping：对常用国内官方域名各 ping 10 次取平均，每测完一个立即显示 (纯本地命令，零依赖)
ping_cn() {
  echo -e "${YELLOW}-- 国内延迟检测 --${NC}"
  local sites=("百度:baidu.com" "腾讯:qq.com" "淘宝:taobao.com" "B站:bilibili.com" "抖音:douyin.com")
  local s name d out avg loss w i ch code
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    # 按显示宽度对齐（中文/全角按 2 列，纯 bash 计算，兼容 mawk/gawk），统一补到 6 列
    w=0
    for ((i=0; i<${#name}; i++)); do
      ch="${name:i:1}"
      printf -v code "%d" "'$ch" 2>/dev/null
      (( code > 127 )) && w=$((w+2)) || w=$((w+1))
    done
    while (( w < 6 )); do name+=" "; w=$((w+1)); done
    out=$(timeout 8 ping -c 10 -i 0.2 -W 1 "$d" 2>/dev/null)
    avg=$(printf '%s\n' "$out" | grep -oE '= [0-9.]+/[0-9.]+/[0-9.]+' | head -1 | sed 's/= //' | cut -d'/' -f2)
    printf '\r\033[K'
    if [ -n "$avg" ]; then
      printf "  %s${GREEN}延迟 %sms${NC}\n" "$name" "$avg"
    else
      printf "  %s${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国际 Ping：对常用国际站点各 ping 10 次取平均，实时显示 (纯本地命令，零依赖)
ping_intl() {
  echo -e "${YELLOW}-- 国际延迟检测 --${NC}"
  local sites=("Google:google.com" "Cloudflare:cloudflare.com" "GitHub:github.com" "YouTube:youtube.com" "Microsoft:microsoft.com")
  local s name d out avg loss
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    out=$(timeout 8 ping -c 10 -i 0.2 -W 1 "$d" 2>/dev/null)
    avg=$(printf '%s\n' "$out" | grep -oE '= [0-9.]+/[0-9.]+/[0-9.]+' | head -1 | sed 's/= //' | cut -d'/' -f2)
    printf '\r\033[K'
    if [ -n "$avg" ]; then
      printf "  %-12s ${GREEN}延迟 %sms${NC}\n" "$name" "$avg"
    else
      printf "  %-12s ${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国内丢包测试：常用国内官方域名各 ping 100 次（1% 粒度），实时显示丢包率
ping_cn_loss() {
  echo -e "${YELLOW}-- 国内丢包检测 --${NC}"
  local sites=("百度:baidu.com" "腾讯:qq.com" "淘宝:taobao.com" "B站:bilibili.com" "抖音:douyin.com")
  local s name d out loss lpct w i ch code
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    # 按显示宽度对齐（中文/全角按 2 列，纯 bash 计算，兼容 mawk/gawk），统一补到 6 列
    w=0
    for ((i=0; i<${#name}; i++)); do
      ch="${name:i:1}"
      printf -v code "%d" "'$ch" 2>/dev/null
      (( code > 127 )) && w=$((w+2)) || w=$((w+1))
    done
    while (( w < 6 )); do name+=" "; w=$((w+1)); done
    out=$(timeout 30 ping -c 100 -i 0.2 -W 1 "$d" 2>/dev/null)
    loss=$(printf '%s\n' "$out" | grep -oE '[0-9]+% packet loss' | head -1)
    printf '\r\033[K'
    if [ -n "$loss" ]; then
      lpct=${loss/ packet loss/}
      if [ "$lpct" = "0%" ]; then
        printf "  %s${GREEN}丢包 %s${NC}\n" "$name" "$lpct"
      else
        printf "  %s${YELLOW}丢包 %s${NC}\n" "$name" "$lpct"
      fi
    else
      printf "  %s${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国际丢包测试：常用国际站点各 ping 100 次（1% 粒度），实时显示丢包率
ping_intl_loss() {
  echo -e "${YELLOW}-- 国际丢包检测 --${NC}"
  local sites=("Google:google.com" "Cloudflare:cloudflare.com" "GitHub:github.com" "YouTube:youtube.com" "Microsoft:microsoft.com")
  local s name d out loss lpct
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    out=$(timeout 30 ping -c 100 -i 0.2 -W 1 "$d" 2>/dev/null)
    loss=$(printf '%s\n' "$out" | grep -oE '[0-9]+% packet loss' | head -1)
    printf '\r\033[K'
    if [ -n "$loss" ]; then
      lpct=${loss/ packet loss/}
      if [ "$lpct" = "0%" ]; then
        printf "  %-12s ${GREEN}丢包 %s${NC}\n" "$name" "$lpct"
      else
        printf "  %-12s ${YELLOW}丢包 %s${NC}\n" "$name" "$lpct"
      fi
    else
      printf "  %-12s ${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国内 IPv6 丢包测试：常用国内官方域名各 ping 100 次（1% 粒度），实时显示丢包率
ping_cn_loss6() {
  echo -e "${YELLOW}-- 国内 IPv6 丢包检测 --${NC}"
  local sites=("百度:www.baidu.com" "腾讯:www.qq.com" "淘宝:www.taobao.com" "B站:www.bilibili.com" "抖音:www.douyin.com")
  local s name d out loss lpct w i ch code
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    # 按显示宽度对齐（中文/全角按 2 列，纯 bash 计算，兼容 mawk/gawk），统一补到 6 列
    w=0
    for ((i=0; i<${#name}; i++)); do
      ch="${name:i:1}"
      printf -v code "%d" "'$ch" 2>/dev/null
      (( code > 127 )) && w=$((w+2)) || w=$((w+1))
    done
    while (( w < 6 )); do name+=" "; w=$((w+1)); done
    out=$(timeout 30 ping -6 -c 100 -i 0.2 -W 1 "$d" 2>/dev/null)
    loss=$(printf '%s\n' "$out" | grep -oE '[0-9]+% packet loss' | head -1)
    printf '\r\033[K'
    if [ -n "$loss" ]; then
      lpct=${loss/ packet loss/}
      if [ "$lpct" = "0%" ]; then
        printf "  %s${GREEN}丢包 %s${NC}\n" "$name" "$lpct"
      else
        printf "  %s${YELLOW}丢包 %s${NC}\n" "$name" "$lpct"
      fi
    else
      printf "  %s${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国际 IPv6 丢包测试：常用国际站点各 ping 100 次（1% 粒度），实时显示丢包率
ping_intl_loss6() {
  echo -e "${YELLOW}-- 国际 IPv6 丢包检测 --${NC}"
  local sites=("Google:www.google.com" "Cloudflare:www.cloudflare.com" "Wikipedia:wikipedia.org" "YouTube:www.youtube.com" "Microsoft:www.microsoft.com")
  local s name d out loss lpct
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    out=$(timeout 30 ping -6 -c 100 -i 0.2 -W 1 "$d" 2>/dev/null)
    loss=$(printf '%s\n' "$out" | grep -oE '[0-9]+% packet loss' | head -1)
    printf '\r\033[K'
    if [ -n "$loss" ]; then
      lpct=${loss/ packet loss/}
      if [ "$lpct" = "0%" ]; then
        printf "  %-12s ${GREEN}丢包 %s${NC}\n" "$name" "$lpct"
      else
        printf "  %-12s ${YELLOW}丢包 %s${NC}\n" "$name" "$lpct"
      fi
    else
      printf "  %-12s ${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国内 IPv6 Ping：对常用国内官方域名各 ping 10 次取平均，实时显示 (需机器有 IPv6)
# 注意：大厂 IPv6 多挂在 www 子域，主域无 AAAA，故统一用 www 前缀
ping_cn6() {
  echo -e "${YELLOW}-- 国内 IPv6 延迟检测 --${NC}"
  local sites=("百度:www.baidu.com" "腾讯:www.qq.com" "淘宝:www.taobao.com" "B站:www.bilibili.com" "抖音:www.douyin.com")
  local s name d out avg loss w i ch code
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    # 按显示宽度对齐（中文/全角按 2 列，纯 bash 计算，兼容 mawk/gawk），统一补到 6 列
    w=0
    for ((i=0; i<${#name}; i++)); do
      ch="${name:i:1}"
      printf -v code "%d" "'$ch" 2>/dev/null
      (( code > 127 )) && w=$((w+2)) || w=$((w+1))
    done
    while (( w < 6 )); do name+=" "; w=$((w+1)); done
    out=$(timeout 8 ping -6 -c 10 -i 0.2 -W 1 "$d" 2>/dev/null)
    avg=$(printf '%s\n' "$out" | grep -oE '= [0-9.]+/[0-9.]+/[0-9.]+' | head -1 | sed 's/= //' | cut -d'/' -f2)
    printf '\r\033[K'
    if [ -n "$avg" ]; then
      printf "  %s${GREEN}延迟 %sms${NC}\n" "$name" "$avg"
    else
      printf "  %s${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 国际 IPv6 Ping：对常用国际站点各 ping 10 次取平均，实时显示 (需机器有 IPv6)
# GitHub 无 AAAA 记录不支持 IPv6，用 Wikipedia 替代
ping_intl6() {
  echo -e "${YELLOW}-- 国际 IPv6 延迟检测 --${NC}"
  local sites=("Google:www.google.com" "Cloudflare:www.cloudflare.com" "Wikipedia:wikipedia.org" "YouTube:www.youtube.com" "Microsoft:www.microsoft.com")
  local s name d out avg loss
  echo -en "${YELLOW}  正在加载...${NC}"
  for s in "${sites[@]}"; do
    name="${s%%:*}"
    d="${s##*:}"
    out=$(timeout 8 ping -6 -c 10 -i 0.2 -W 1 "$d" 2>/dev/null)
    avg=$(printf '%s\n' "$out" | grep -oE '= [0-9.]+/[0-9.]+/[0-9.]+' | head -1 | sed 's/= //' | cut -d'/' -f2)
    printf '\r\033[K'
    if [ -n "$avg" ]; then
      printf "  %-12s ${GREEN}延迟 %sms${NC}\n" "$name" "$avg"
    else
      printf "  %-12s ${RED}无法连通${NC}\n" "$name"
    fi
    echo -en "${YELLOW}  正在加载...${NC}"
  done
  printf '\r\033[K'
  echo ""
}

# 整合 IPv4 Ping：依次测国内、国际，各测 10 次实时显示
ping_both4() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  ping_cn
  ping_intl
}

# 整合 IPv6 Ping：依次测国内、国际，各测 10 次实时显示
ping_both6() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  ping_cn6
  ping_intl6
}

# 整合 IPv4 丢包测试：依次测国内、国际，各测 100 次实时显示丢包率
loss_both4() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  ping_cn_loss
  ping_intl_loss
}

# 整合 IPv6 丢包测试：依次测国内、国际，各测 100 次实时显示丢包率
loss_both6() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  ping_cn_loss6
  ping_intl_loss6
}

# 自定义 Ping：输入 IP 或域名，ping 10 次取平均；输入 IPv6 地址自动识别
ping_custom() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  echo -e "${YELLOW}-- 自定义 Ping --${NC}"
  local target out avg
  read -p "  请输入 IP 或域名: " target
  if [ -z "$target" ]; then
    echo -e "${RED}  输入为空，已取消${NC}"
    return
  fi
  echo -en "${YELLOW}  正在加载...${NC}"
  if echo "$target" | grep -q ':'; then
    out=$(timeout 8 ping -6 -c 10 -i 0.2 -W 1 "$target" 2>/dev/null)
  else
    out=$(timeout 8 ping -c 10 -i 0.2 -W 1 "$target" 2>/dev/null)
  fi
  avg=$(printf '%s\n' "$out" | grep -oE '= [0-9.]+/[0-9.]+/[0-9.]+' | head -1 | sed 's/= //' | cut -d'/' -f2)
  printf '\r\033[K'
  if [ -n "$avg" ]; then
    printf "  %-15s ${GREEN}延迟 %sms${NC}\n" "$target" "$avg"
  else
    printf "  %-15s ${RED}无法连通${NC}\n" "$target"
  fi
  echo ""
}

# 自定义丢包测试：输入 IP 或域名，ping 100 次（1% 粒度）；输入 IPv6 地址自动识别
ping_custom_loss() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  echo -e "${YELLOW}-- 自定义丢包测试 --${NC}"
  local target out loss lpct
  read -p "  请输入 IP 或域名: " target
  if [ -z "$target" ]; then
    echo -e "${RED}  输入为空，已取消${NC}"
    return
  fi
  echo -en "${YELLOW}  正在加载...${NC}"
  if echo "$target" | grep -q ':'; then
    out=$(timeout 30 ping -6 -c 100 -i 0.2 -W 1 "$target" 2>/dev/null)
  else
    out=$(timeout 30 ping -c 100 -i 0.2 -W 1 "$target" 2>/dev/null)
  fi
  loss=$(printf '%s\n' "$out" | grep -oE '[0-9]+% packet loss' | head -1)
  printf '\r\033[K'
  if [ -n "$loss" ]; then
    lpct=${loss/ packet loss/}
    if [ "$lpct" = "0%" ]; then
      printf "  %-15s ${GREEN}丢包 %s${NC}\n" "$target" "$lpct"
    else
      printf "  %-15s ${YELLOW}丢包 %s${NC}\n" "$target" "$lpct"
    fi
  else
    printf "  %-15s ${RED}无法连通${NC}\n" "$target"
  fi
  echo ""
}

# 国家码 → 中文名
glob_country_name() {
  case "$1" in
    US) echo "美国" ;; CA) echo "加拿大" ;; MX) echo "墨西哥" ;;
    BR) echo "巴西" ;; CL) echo "智利" ;; AR) echo "阿根廷" ;; CO) echo "哥伦比亚" ;; PE) echo "秘鲁" ;; EC) echo "厄瓜多尔" ;; BO) echo "玻利维亚" ;; TT) echo "特立尼达和多巴哥" ;;
    GB) echo "英国" ;; DE) echo "德国" ;; NL) echo "荷兰" ;; FR) echo "法国" ;; RU) echo "俄罗斯" ;; FI) echo "芬兰" ;; SE) echo "瑞典" ;; PL) echo "波兰" ;; AT) echo "奥地利" ;; RO) echo "罗马尼亚" ;; CH) echo "瑞士" ;; IT) echo "意大利" ;; ES) echo "西班牙" ;; PT) echo "葡萄牙" ;; NO) echo "挪威" ;; BG) echo "保加利亚" ;; IE) echo "爱尔兰" ;; UA) echo "乌克兰" ;; DK) echo "丹麦" ;; CZ) echo "捷克" ;; LV) echo "拉脱维亚" ;; HU) echo "匈牙利" ;; SK) echo "斯洛伐克" ;; RS) echo "塞尔维亚" ;; MD) echo "摩尔多瓦" ;; BE) echo "比利时" ;; AL) echo "阿尔巴尼亚" ;; HR) echo "克罗地亚" ;; GR) echo "希腊" ;; EE) echo "爱沙尼亚" ;; BY) echo "白俄罗斯" ;; MT) echo "马耳他" ;; LU) echo "卢森堡" ;; LT) echo "立陶宛" ;; MK) echo "北马其顿" ;; IS) echo "冰岛" ;; CY) echo "塞浦路斯" ;; AD) echo "安道尔" ;; XK) echo "科索沃" ;;
    JP) echo "日本" ;; SG) echo "新加坡" ;; HK) echo "香港" ;; CN) echo "中国" ;; IN) echo "印度" ;; ID) echo "印度尼西亚" ;; TH) echo "泰国" ;; TW) echo "台湾" ;; KR) echo "韩国" ;; MY) echo "马来西亚" ;; TR) echo "土耳其" ;; VN) echo "越南" ;; BD) echo "孟加拉" ;; PK) echo "巴基斯坦" ;; PH) echo "菲律宾" ;; IL) echo "以色列" ;; AE) echo "阿联酋" ;; SA) echo "沙特阿拉伯" ;; KZ) echo "哈萨克斯坦" ;; AZ) echo "阿塞拜疆" ;; LA) echo "老挝" ;; QA) echo "卡塔尔" ;; OM) echo "阿曼" ;; MV) echo "马尔代夫" ;; MO) echo "澳门" ;; KW) echo "科威特" ;; BH) echo "巴林" ;; YE) echo "也门" ;; AM) echo "亚美尼亚" ;;
    AU) echo "澳大利亚" ;; NZ) echo "新西兰" ;; VU) echo "瓦努阿图" ;;
    ZA) echo "南非" ;; NG) echo "尼日利亚" ;; UG) echo "乌干达" ;; AO) echo "安哥拉" ;; MA) echo "摩洛哥" ;;
    BA) echo "波黑" ;; BF) echo "布基纳法索" ;; CR) echo "哥斯达黎加" ;; CW) echo "库拉索" ;; EG) echo "埃及" ;; GE) echo "格鲁吉亚" ;; GU) echo "关岛" ;; IR) echo "伊朗" ;; KE) echo "肯尼亚" ;; KG) echo "吉尔吉斯斯坦" ;; NA) echo "纳米比亚" ;; PA) echo "巴拿马" ;; PY) echo "巴拉圭" ;; RE) echo "留尼汪" ;; SB) echo "所罗门群岛" ;; SC) echo "塞舌尔" ;; SI) echo "斯洛文尼亚" ;; SL) echo "塞拉利昂" ;; SV) echo "萨尔瓦多" ;; TJ) echo "塔吉克斯坦" ;; UY) echo "乌拉圭" ;; KH) echo "柬埔寨" ;; NP) echo "尼泊尔" ;; MM) echo "缅甸" ;; LB) echo "黎巴嫩" ;;
    *) echo "$1" ;;
  esac
}

# 大洲码 → 中文名
glob_continent_name() {
  case "$1" in
    AS) echo "亚洲" ;; EU) echo "欧洲" ;; NA) echo "北美" ;;
    SA) echo "南美" ;; OC) echo "大洋洲" ;; AF) echo "非洲" ;;
    *) echo "$1" ;;
  esac
}

# 从指定国家节点检测本机 IP（limit 5，不足自动取实际数量）$3=地址类型标签(IPv4/IPv6)
glob_test_country() {
  local ip="$1" cc="$2" label="$3" resp mid res raw avg loss_pct city w i ch code
  clear
  echo -e "${CYAN}────────── Globalping ──────────${NC}"
  echo -e "  测试目标: ${GREEN}$ip${NC} (${label:-IPv4})"
  echo -e "${YELLOW}-- 正在从 $(glob_country_name "$cc") 节点检测 --${NC}"
  resp=$(curl -s --noproxy '*' --connect-timeout 10 --max-time 20 -X POST "https://api.globalping.io/v1/measurements" -H "Content-Type: application/json" -d "{\"type\":\"ping\",\"target\":\"$ip\",\"limit\":5,\"locations\":[{\"country\":\"$cc\"}]}")
  mid=$(printf '%s' "$resp" | grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)
  if [ -z "$mid" ]; then
    echo -e "${RED}  请求失败，请检查网络${NC}"
    echo ""
    sleep 1
    return
  fi
  # 轮询结果，最多 30 秒；接口异常时提前退出，避免长时间卡住
  for i in $(seq 1 15); do
    sleep 2
    res=$(curl -s --noproxy '*' --connect-timeout 10 --max-time 30 "https://api.globalping.io/v1/measurements/$mid" -H "Accept: application/json")
    [ -z "$res" ] && break
    printf '%s' "$res" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"finished"' && break
  done
  # 最终仍未完成或结果为空时明确提示，避免白屏
  if ! printf '%s' "$res" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"finished"'; then
    echo -e "${RED}  检测超时或无结果，请稍后重试${NC}"
    echo ""
    sleep 1
    return
  fi
  # 逐节点解析显示（grep 交替提取 city/rawOutput，兼容 mawk）
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -q '"city"'; then
      city=$(printf '%s' "$line" | cut -d'"' -f4)
      [ -z "$city" ] && city="未知"
      # 按显示宽度对齐（中文/全角按 2 列），统一补到 12 列
      w=0
      for ((i=0; i<${#city}; i++)); do
        ch="${city:i:1}"
        printf -v code "%d" "'$ch" 2>/dev/null
        (( code > 127 )) && w=$((w+2)) || w=$((w+1))
      done
      while (( w < 12 )); do city+=" "; w=$((w+1)); done
    else
      raw=$(printf '%s' "$line" | cut -d'"' -f4 | sed 's/\\n/\n/g')
      avg=$(printf '%s\n' "$raw" | grep -oE '= [0-9.]+/[0-9.]+/[0-9.]+' | head -1 | sed 's/= //' | cut -d'/' -f2)
      loss_pct=$(printf '%s\n' "$raw" | grep -oE '[0-9]+% packet loss' | head -1 | grep -oE '^[0-9]+')
      if [ -n "$avg" ]; then
        if [ "${loss_pct:-0}" = "0" ]; then
          printf "  %s${GREEN}延迟 %sms${NC}  (0%% 丢包)\n" "$city" "$avg"
        else
          printf "  %s${YELLOW}延迟 %sms${NC}  (丢包 %s%%)\n" "$city" "$avg" "$loss_pct"
        fi
      else
        printf "  %s${RED}无法连通${NC}\n" "$city"
      fi
    fi
  done < <(printf '%s' "$res" | grep -oE '"city"[[:space:]]*:[[:space:]]*"[^"]*"|"rawOutput"[[:space:]]*:[[:space:]]*"[^"]*"')
  echo ""
}

# 某大洲的国家选择菜单（ip=出口IPv4, ip6=出口IPv6, 双栈时测试前询问 4/6）
glob_country_menu() {
  local cont="$1" ip="$2" ip6="$3" data="$4"
  local cc_list=() cnt_list=() line cnt cc gsel i tv
  while IFS= read -r line; do
    set -- $line
    cnt=$1; cc=${2#*:}
    cc_list+=("$cc"); cnt_list+=("$cnt")
  done < <(printf '%s\n' "$data" | grep " $cont:")
  while true; do
    clear
    echo -e "${CYAN}────────── Globalping ──────────${NC}"
    [ -n "$ip" ] && echo -e "  本机 IPv4: ${GREEN}$ip${NC}"
    [ -n "$ip6" ] && echo -e "  本机 IPv6: ${GREEN}$ip6${NC}"
    echo ""
    echo -e "${YELLOW}-- $(glob_continent_name "$cont") --${NC}"
    echo "  ──────────────────────────────────────"
    for i in "${!cc_list[@]}"; do
      printf "   ${GREEN}%d${NC}) %s (%s节点)\n" "$((i+1))" "$(glob_country_name "${cc_list[$i]}")" "${cnt_list[$i]}"
    done
    echo -e "   ${GREEN}0${NC}) 返回大洲"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " gsel
    if [ "$gsel" = "0" ]; then return 0; fi
    if [ "$gsel" -ge 1 ] 2>/dev/null && [ "$gsel" -le "${#cc_list[@]}" ]; then
      if [ -n "$ip" ] && [ -n "$ip6" ]; then
        # 双栈：测试前询问测 IPv4 还是 IPv6
        while true; do
          echo ""
          echo -en "  请选择测试目标 IPv4(${GREEN}4${NC}) 或 IPv6(${GREEN}6${NC}): "
          read -r tv
          case "$tv" in
            4) glob_test_country "$ip" "${cc_list[$((gsel-1))]}" "IPv4"; break ;;
            6) glob_test_country "$ip6" "${cc_list[$((gsel-1))]}" "IPv6"; break ;;
            *) echo -e "${RED}  无效选项，请输入 4 或 6${NC}" ;;
          esac
        done
      elif [ -n "$ip6" ]; then
        glob_test_country "$ip6" "${cc_list[$((gsel-1))]}" "IPv6"
      else
        glob_test_country "$ip" "${cc_list[$((gsel-1))]}" "IPv4"
      fi
      read -p "  按回车返回国家列表..."
    else
      echo -e "${RED}  无效选项，请重新输入${NC}"
      sleep 1
    fi
  done
}

# Globalping：实时拉取官方国家列表 → 选大洲 → 选国家 → 从该国节点检测本机 (IPv4/IPv6)
ping_global() {
  local ip ip6 data conts c nc idx csel
  clear
  echo -e "${CYAN}────────── Globalping ──────────${NC}"
  echo -en "${YELLOW}  正在加载...${NC}"
  get_pub_ip
  ip="$PUB_IP"
  get_pub_ip6
  ip6="$PUB_IP6"
  if [ -z "$ip" ] && [ -z "$ip6" ]; then
    printf '\r\033[K'
    echo -e "${RED}  获取出口 IPv4/IPv6 失败，请检查网络${NC}"
    echo ""
    read -p "  按回车返回主菜单..."
    return
  fi
  # 实时拉取官方节点列表（先下载到变量，失败可区分原因）
  local probes_raw
  probes_raw=$(curl -s --noproxy '*' --connect-timeout 10 --max-time 50 "https://api.globalping.io/v1/probes" -H "Accept: application/json")
  if [ -z "$probes_raw" ]; then
    printf '\r\033[K'
    echo -e "${RED}  获取国家列表失败（接口无响应，超时或被阻断）${NC}"
    echo ""
    read -p "  按回车返回主菜单..."
    return
  fi
  # 统计 "数量 洲:国"（grep 交替配对 + cut 取值，兼容 mawk 与两种 JSON 格式）
  data=$(printf '%s' "$probes_raw" | grep -oE '"(continent|country)"[[:space:]]*:[[:space:]]*"[A-Z]{2}"' | cut -d'"' -f4 | awk 'NR%2==1 { c=$0 } NR%2==0 { print c":"$0 }' | sort | uniq -c | sort -rn)
  printf '\r\033[K'
  if [ -z "$data" ]; then
    echo -e "${RED}  获取国家列表失败（数据解析为空）${NC}"
    echo ""
    read -p "  按回车返回主菜单..."
    return
  fi
  # 有节点的洲
  conts=()
  for c in AS EU NA SA OC AF; do
    printf '%s\n' "$data" | grep -q " $c:" && conts+=("$c")
  done
  while true; do
    clear
    echo -e "${CYAN}────────── Globalping ──────────${NC}"
    [ -n "$ip" ] && echo -e "  本机 IPv4: ${GREEN}$ip${NC}"
    [ -n "$ip6" ] && echo -e "  本机 IPv6: ${GREEN}$ip6${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    idx=1
    for c in "${conts[@]}"; do
      nc=$(printf '%s\n' "$data" | grep " $c:" | wc -l)
      printf "   ${GREEN}%d${NC}) %s (%d国)\n" "$idx" "$(glob_continent_name "$c")" "$nc"
      idx=$((idx+1))
    done
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " csel
    if [ "$csel" = "0" ]; then
      clear
      echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
      echo ""
      return
    fi
    if [ "$csel" -ge 1 ] 2>/dev/null && [ "$csel" -le "${#conts[@]}" ]; then
      glob_country_menu "${conts[$((csel-1))]}" "$ip" "$ip6" "$data" || return
    else
      echo -e "${RED}  无效选项，请重新输入${NC}"
      sleep 1
    fi
  done
}

# Ping 测试入口
sys_ping() {
  clear
  echo -e "${CYAN}────────── Ping 测试 ──────────${NC}"
  echo ""
  ping_action
}

# ---------- 主循环 ----------
while true; do
  menu
  case "$choice" in
    1) sys_status; read -p "  按回车返回菜单..." ;;
    2) sys_net ;;
    3) sys_logs ;;
    4) sys_clean ;;
    5) sys_tools ;;
    6) sys_ports ;;
    7) sys_ufw ;;
    8) sys_files ;;
    9) sys_packages ;;
    10) sys_bbr ;;
    11) sys_proxy ;;
    12) sys_ping ;;
    13) sys_notes ;;
    0) echo "  再见"; exit 0 ;;
    *) ;;
  esac
done
