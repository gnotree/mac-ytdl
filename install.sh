#!/bin/bash
# install.sh - Setup ytdl CLI wrapper on macOS
# Grant Scott Turner 2025

set -e

### Color output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

### Check for Homebrew
if ! command -v brew &>/dev/null; then
  echo -e "${GREEN}[+] Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

### Ensure dependencies are installed
REQUIRED_PKGS=(yt-dlp ffmpeg)
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! brew list "$pkg" &>/dev/null; then
    echo -e "${GREEN}[+] Installing $pkg...${NC}"
    brew install "$pkg"
  fi
done

### Inject functions into ~/.zshrc if not already there
ZSHRC="$HOME/.zshrc"
FUNC_BLOCK_START="# >>> ytdl-wrapper start >>>"
FUNC_BLOCK_END="# <<< ytdl-wrapper end <<<"

if ! grep -q "$FUNC_BLOCK_START" "$ZSHRC"; then
  cat <<'EOF' >> "$ZSHRC"

$FUNC_BLOCK_START

# ytdl: Interactive YouTube downloader
ytdl() {
  echo -n "Enter YouTube URL or comma-separated list: "
  read input

  echo -n "Download audio (A) or video (V)? [A/V]: "
  read mode

  if [[ ! "$mode" =~ ^[AaVv]$ ]]; then
    echo "[-] Invalid mode: Must be A or V"
    return 1
  fi

  IFS=',' read -A urls <<< "$input"
  for url in "${urls[@]}"; do
    url="${url// /}"
    if [[ "$url" =~ ^https?:// ]]; then
      if [[ "$mode" =~ ^[Aa]$ ]]; then
        echo "[AUDIO] Downloading: $url"
        yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --extract-audio --audio-format m4a "$url"
      else
        echo "[VIDEO] Downloading: $url"
        yt-dlp -f "bestvideo+bestaudio/best" "$url"
      fi
    else
      echo "[-] Skipping invalid URL: $url"
    fi
  done
}

# ytdl-clippy: Clipboard-based batch downloader
ytdl-clippy() {
  clipboard=$(pbpaste)
  IFS=',' read -A urls <<< "$clipboard"
  for url in "${urls[@]}"; do
    url="${url// /}"
    if [[ "$url" =~ ^https?:// ]]; then
      echo "[clippy] Downloading: $url"
      yt-dlp -f "bestvideo+bestaudio/best" "$url"
    else
      echo "[clippy] Skipping invalid entry: $url"
    fi
  done
}

$FUNC_BLOCK_END
EOF

  echo -e "${GREEN}[✓] ytdl and ytdl-clippy added to ~/.zshrc${NC}"
else
  echo -e "${GREEN}[✓] Functions already exist in ~/.zshrc${NC}"
fi

### Final message
echo -e "\n${GREEN}[!] Run 'source ~/.zshrc' or restart your terminal to activate ytdl commands.${NC}"
