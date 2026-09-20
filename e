#!/bin/bash
# ============================================
#  Easy 管理面板  v1.1
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
  echo "                  E a s y 管 理 面 板  v1.1"
  printf '\033[0m'
  echo ""
}

# ---------- 菜单 ----------
menu() {
  cover
  echo ""
  echo "  ──────────────────────────────────────"
  echo -e "   ${GREEN}1${NC}) 系统状态"
  echo -e "   ${GREEN}2${NC}) 系统日志"
  echo -e "   ${GREEN}3${NC}) 清理垃圾"
  echo -e "   ${GREEN}4${NC}) 系统工具"
  echo -e "   ${GREEN}5${NC}) 端口状态"
  echo -e "   ${GREEN}6${NC}) 防火墙管理"
  echo -e "   ${GREEN}7${NC}) 文件管理"
  echo -e "   ${GREEN}8${NC}) 软件管理"
  echo -e "   ${GREEN}9${NC}) BBR 加速"
  echo -e "  ${GREEN}10${NC}) 记事本"
  echo -e "  ${GREEN}11${NC}) 退出"
  echo "  ──────────────────────────────────────"
  echo ""
  read -p "  请输入选项 [1-10]: " choice
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
    read -p "  请选择: " opt
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
    freed=$(awk -v b="$before" -v a="$after" 'BEGIN {print b - a}')
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
  # 备份现有源
  [ -f /etc/apt/sources.list ] && cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)
  [ -f /etc/apt/sources.list.d/debian.sources ] && cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak.$(date +%Y%m%d%H%M%S)
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
      3)
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
    read -p "  请选择: " opt
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
        # 修改 sshd_config (先备份)
        local bakfile="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
        cp /etc/ssh/sshd_config "$bakfile"
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
            cp "$bakfile" /etc/ssh/sshd_config
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
            echo -e "${YELLOW}  已回滚到原配置，端口未修改${NC}"
          fi
        else
          echo -e "${RED}  警告: sshd 重启失败，正在回滚...${NC}"
          cp "$bakfile" /etc/ssh/sshd_config
          systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
          echo -e "${YELLOW}  已回滚到原配置，端口未修改${NC}"
        fi
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
    echo "   1) 中国北京  (Asia/Shanghai)"
    echo "   2) 中国香港  (Asia/Hong_Kong)"
    echo "   3) 中国台湾  (Asia/Taipei)"
    echo "   4) 日本      (Asia/Tokyo)"
    echo "   5) 韩国      (Asia/Seoul)"
    echo "   6) 新加坡    (Asia/Singapore)"
    echo "   7) 美国东部  (America/New_York)"
    echo "   8) 美国西部  (America/Los_Angeles)"
    echo "   9) 英国      (Europe/London)"
    echo "  10) 德国      (Europe/Berlin)"
    echo "  11) 俄罗斯    (Europe/Moscow)"
    echo "  12) 澳大利亚  (Australia/Sydney)"
    echo "   0) 返回系统工具"
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
    echo "   1) 简体中文  (zh_CN.UTF-8)"
    echo "   2) 繁体中文  (zh_TW.UTF-8)"
    echo "   3) 英语(美)  (en_US.UTF-8)"
    echo "   4) 英语(英)  (en_GB.UTF-8)"
    echo "   5) 日语      (ja_JP.UTF-8)"
    echo "   6) 韩语      (ko_KR.UTF-8)"
    echo "   7) 德语      (de_DE.UTF-8)"
    echo "   8) 法语      (fr_FR.UTF-8)"
    echo "   9) 俄语      (ru_RU.UTF-8)"
    echo "  10) 西班牙语  (es_ES.UTF-8)"
    echo "   0) 返回系统工具"
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

sys_hotkey() {
  self_path=$(readlink -f "$0")
  cur_name=$(basename "$self_path")
  while true; do
    clear
    echo -e "${CYAN}────────── 设置启动快捷键 ──────────${NC}"
    echo -e "  当前快捷键: ${GREEN}${cur_name}${NC} (输入 ${cur_name} 打开菜单)"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 设置快捷键"
    echo -e "   ${GREEN}0${NC}) 返回系统工具"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1)
        read -p "  输入新快捷键 (如 s、m，仅限字母数字): " new
        if echo "$new" | grep -qE '^[a-zA-Z0-9]{1,16}$'; then
          newpath="/usr/local/bin/$new"
          if [ -e "$newpath" ] && [ "$newpath" != "$self_path" ]; then
            echo -e "${RED}  $newpath 已存在，请换个名字${NC}"
          elif [ "$newpath" = "$self_path" ]; then
            echo -e "${YELLOW}  快捷键未变化${NC}"
          else
            mv "$self_path" "$newpath" && {
              cur_name="$new"
              self_path="$newpath"
              echo -e "${GREEN}  快捷键已改为: $new (下次输入 $new 打开)${NC}"
            } || echo -e "${RED}  修改失败 (权限不足?)${NC}"
          fi
        else
          echo -e "${RED}  无效输入 (仅限字母数字，16字符内)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      0) return ;;
      *) ;;
    esac
  done
}

sys_schedule_reboot() {
  while true; do
    clear
    echo -e "${CYAN}────────── 定时重启 ──────────${NC}"
    echo ""
    if [ -f /etc/systemd/system/reboot.timer ]; then
      interval=$(grep -oP 'OnUnitActiveSec=\K\S+' /etc/systemd/system/reboot.timer 2>/dev/null)
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
  clear
  echo -e "${CYAN}────────── 更新脚本 ──────────${NC}"
  echo -e "${YELLOW}  将从 GitHub 下载最新版脚本覆盖当前版本${NC}"
  echo -e "${YELLOW}  仓库地址: https://github.com/smallsmalldou/Easylinux${NC}"
  echo -e "${YELLOW}  您的笔记文件不会被删除${NC}"
  echo ""
  if confirm "确认更新脚本?"; then
    echo -e "${YELLOW}  正在下载...${NC}"
    if curl -sL https://raw.githubusercontent.com/smallsmalldou/Easylinux/main/e -o /usr/local/bin/e && chmod +x /usr/local/bin/e; then
      echo -e "${GREEN}  更新完成，即将重启脚本...${NC}"
      sleep 1
      exec /usr/local/bin/e
    else
      echo -e "${RED}  更新失败，请检查网络或 GitHub 地址${NC}"
      read -p "  按回车继续..."
    fi
  else
    echo "  已取消"
    read -p "  按回车继续..."
  fi
}

sys_uninstall() {
  self_path=$(readlink -f "$0")
  clear
  echo -e "${CYAN}────────── 卸载脚本 ──────────${NC}"
  echo -e "  将删除脚本: ${self_path}"
  if [ -f "$NOTES_FILE" ]; then
    echo -e "  将删除笔记: ${NOTES_FILE}"
  fi
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

sys_tools() {
  while true; do
    clear
    echo -e "${CYAN}────────── 系统工具 ──────────${NC}"
    echo ""
    echo "  ──────────────────────────────────────"
    echo -e "   ${GREEN}1${NC}) 软件源管理"
    echo -e "   ${GREEN}2${NC}) 虚拟内存设置"
    echo -e "   ${GREEN}3${NC}) SSH 端口修改"
    echo -e "   ${GREEN}4${NC}) 设置时区"
    echo -e "   ${GREEN}5${NC}) 设置语言"
    echo -e "   ${GREEN}6${NC}) 设置主机名"
    echo -e "   ${GREEN}7${NC}) 设置登录密码"
    echo -e "   ${GREEN}8${NC}) 设置启动快捷键"
    echo -e "   ${GREEN}9${NC}) 定时重启"
    echo -e "  ${GREEN}10${NC}) 重启服务器"
    echo -e "  ${GREEN}11${NC}) 更新脚本"
    echo -e "  ${GREEN}12${NC}) 卸载脚本"
    echo -e "   ${GREEN}0${NC}) 返回主菜单"
    echo "  ──────────────────────────────────────"
    echo ""
    read -p "  请输入选项: " opt
    case "$opt" in
      1) sys_apt_sources ;;
      2) sys_swap ;;
      3) sys_ssh_port ;;
      4) sys_timezone ;;
      5) sys_locale ;;
      6) sys_hostname ;;
      7) sys_passwd ;;
      8) sys_hotkey ;;
      9) sys_schedule_reboot ;;
      10) sys_reboot ;;
      11) sys_update ;;
      12) sys_uninstall ;;
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
sys_ufw() {
  clear
  echo -e "${CYAN}────────── 防火墙管理 ──────────${NC}"

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
    echo -e "${YELLOW}-- 当前防火墙状态 --${NC}"
    if ufw status | grep -q "Status: active"; then
      echo -e "   ${GREEN}已开启 (active)${NC}"
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
    echo -e "   ${GREEN}1${NC}) 放行端口"
    echo -e "   ${GREEN}2${NC}) 取消放行端口"
    echo -e "   ${GREEN}3${NC}) 开启防火墙"
    echo -e "   ${GREEN}4${NC}) 关闭防火墙"
    echo -e "   ${GREEN}5${NC}) 重置默认策略"
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
          ufw allow "$port" && echo -e "${GREEN}  已放行 ${port}${NC}" || echo -e "${RED}  操作失败${NC}"
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
          ufw delete allow "$port" && echo -e "${GREEN}  已取消 ${port}${NC}" || echo -e "${RED}  操作失败(可能未放行)${NC}"
        else
          echo -e "${RED}  无效输入 (示例: 80 或 80/tcp 或 80/udp)${NC}"
        fi
        read -p "  按回车继续..."
        ;;
      3)
        if confirm "确认开启防火墙?"; then
          # 保护：确保 22 端口已放行，防止开启防火墙后锁死 SSH
          if ! ufw status | grep -qE '^22/tcp'; then
            echo -e "${YELLOW}  检测到 22 端口未放行，为防止锁死 SSH，自动放行 22/tcp...${NC}"
            ufw allow 22/tcp
          fi
          echo -e "${YELLOW}  开启防火墙中...${NC}"
          ufw --force enable
          echo -e "${GREEN}  防火墙已开启 (开机自启)${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      4)
        if confirm "确认关闭防火墙 (所有端口将暴露)?"; then
          echo -e "${YELLOW}  关闭防火墙中...${NC}"
          ufw disable
          echo -e "${YELLOW}  防火墙已关闭 (重启后仍保持关闭)${NC}"
        else
          echo "  已取消"
        fi
        read -p "  按回车继续..."
        ;;
      5)
        if confirm "确认重置默认策略 (入站拒绝/出站允许)?"; then
          echo -e "${YELLOW}  重置默认策略为: 入站拒绝 / 出站允许${NC}"
          ufw default deny incoming
          ufw default allow outgoing
          echo -e "${GREEN}  默认策略已重置 (进站全封，出站全开)${NC}"
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
    touch "$NOTES_FILE"
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
              read -p "  请选择: " fop
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
            read -p "  请选择: " pop
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

# ---------- 主循环 ----------
while true; do
  menu
  case "$choice" in
    1) sys_status; read -p "  按回车返回菜单..." ;;
    2) sys_logs ;;
    3) sys_clean ;;
    4) sys_tools ;;
    5) sys_ports ;;
    6) sys_ufw ;;
    7) sys_files ;;
    8) sys_packages ;;
    9) sys_bbr ;;
    10) sys_notes ;;
    11) echo "  再见"; exit 0 ;;
    *) ;;
  esac
done
