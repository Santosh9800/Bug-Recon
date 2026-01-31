#!/usr/bin/env bash
# ==========================================================
# WhiteDevil-Recon PRO v2.2.0
# Author  : Santosh Chhetri
# Channel : Master in White Devil
# ==========================================================

set -e

BIN="/usr/local/bin"
OUT="$HOME/white-devil-output/$(date +%F_%H-%M)"
mkdir -p "$OUT"

# =============== COLORS =================
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"
BLUE="\e[34m"; PURPLE="\e[35m"; CYAN="\e[36m"
BOLD="\e[1m"; RESET="\e[0m"

ok(){ echo -e "${GREEN}${BOLD}[✔]${RESET} $1"; }
info(){ echo -e "${CYAN}${BOLD}[*]${RESET} $1"; }
warn(){ echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
err(){ echo -e "${RED}${BOLD}[✘]${RESET} $1"; }

# =============== BANNER =================
VERSION=2.0.0
banner() {
clear
echo -e "${GREEN}"
cat << "EOF"
███████  █████  ███    ██ ████████  ██████  ███████ ██   ██
██      ██   ██ ████   ██    ██    ██    ██ ██      ██   ██
███████ ███████ ██ ██  ██    ██    ██    ██ ███████ ███████
     ██ ██   ██ ██  ██ ██    ██    ██    ██      ██ ██   ██
███████ ██   ██ ██   ████    ██     ██████  ███████ ██   ██

                ⚡ Tool By: SANTOSH CHHETRI ⚡
EOF
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${YELLOW}Version :${RESET} ${WHITE}${VERSION}${RESET}"
echo -e "${YELLOW}Author  :${RESET} ${WHITE}Santosh Chhetri${RESET}"
echo -e "${YELLOW}Channel :${RESET} ${WHITE}Master in White Devil${RESET}"
echo -e "${YELLOW}GitHub  :${RESET} ${WHITE}Santosh9800${RESET}"
echo -e "${YELLOW}Number  :${RESET} ${WHITE}+977 9819470342${RESET}"
echo -e "${YELLOW}Message :${RESET} ${WHITE}Happy Hunting! Enjoy this tools ❤️${RESET}"
echo -e "${RED}WARNING :${RESET} ${WHITE}Be Careful! While Testing!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
}
# =============== INSTALL ALL =================
install_all(){
info "Installing / Updating ALL Bug Bounty Tools"

apt update -y
apt install -y git curl wget unzip jq python3 python3-pip nmap masscan sqlmap amass gobuster feroxbuster eyewitness

go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/hahwul/dalfox/v2@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/ffuf/ffuf@latest

cp ~/go/bin/* "$BIN/" 2>/dev/null || true
chmod +x "$BIN/"*

[[ ! -d /root/nuclei-templates ]] && git clone https://github.com/projectdiscovery/nuclei-templates /root/nuclei-templates

ok "ALL tools installed & updated"
}

# =============== RECON ENGINE =================
recon_scan(){
read -p "Enter target domain (example.com): " domain
mkdir -p "$OUT/$domain"

info "Subdomain Enumeration"
subfinder -d $domain -silent > "$OUT/$domain/subs.txt"
assetfinder --subs-only $domain >> "$OUT/$domain/subs.txt"
sort -u "$OUT/$domain/subs.txt" -o "$OUT/$domain/subs.txt"
ok "Subdomains: $(wc -l < $OUT/$domain/subs.txt)"

info "Live Host Scan"
httpx -silent -threads 100 < "$OUT/$domain/subs.txt" > "$OUT/$domain/live.txt"
ok "Live Hosts: $(wc -l < $OUT/$domain/live.txt)"

info "URL Collection"
gau $domain > "$OUT/$domain/urls.txt"
waybackurls $domain >> "$OUT/$domain/urls.txt"
sort -u "$OUT/$domain/urls.txt" -o "$OUT/$domain/urls.txt"
ok "URLs: $(wc -l < $OUT/$domain/urls.txt)"

info "Extracting Parameters"
grep "=" "$OUT/$domain/urls.txt" > "$OUT/$domain/params.txt"
ok "Params: $(wc -l < $OUT/$domain/params.txt)"

info "XSS Scan (Dalfox)"
dalfox file "$OUT/$domain/params.txt" -o "$OUT/$domain/xss.txt" || true

info "SQLi Scan (SQLMap – light)"
sqlmap -m "$OUT/$domain/params.txt" --batch --level=1 --risk=1 --output-dir="$OUT/$domain/sqlmap" || true

info "Nuclei Scan"
nuclei -l "$OUT/$domain/live.txt" -t /root/nuclei-templates -o "$OUT/$domain/nuclei.txt" || true

ok "Recon completed"
echo -e "${CYAN}Results saved in: ${YELLOW}$OUT/$domain${RESET}"
}

# =============== MENU =================
menu(){
banner
echo -e "${GREEN}[1]${RESET} Update & Install ALL Bug Bounty Tools"
echo -e "${GREEN}[2]${RESET} Recon & Scan Target"
echo -e "${RED}[99]${RESET} Exit"
echo ""
read -p "Select option: " opt

case $opt in
  1) install_all ;;
  2) recon_scan ;;
  99) exit 0 ;;
  *) warn "Invalid option" ;;
esac
}

# =============== LOOP =================
while true; do
  menu
  echo ""
  read -p "Press Enter to continue..."
done

