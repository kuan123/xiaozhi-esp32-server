#!/bin/sh
set -eu

target="${1:-main/xiaozhi-server/models/sherpa-tts}"
mkdir -p "$target"
cd "$target"
base=https://github.com/k2-fsa/sherpa-onnx/releases/download
aria2_bin="${ARIA2_BIN:-}"

download() {
  output="$1"
  url="$2"
  if [ -n "$aria2_bin" ]; then
    "$aria2_bin" -c -x 8 -s 8 --file-allocation=none \
      --quiet=true -d . -o "$output" "$url"
  else
    curl -fsSL --retry 3 --retry-delay 3 -C - -o "$output" "$url"
  fi
}

digest_for() {
  case "$1" in
    matcha-icefall-zh-en) echo 271b804af570400d3bcdcb53bf6e53cc9f75180ee763b9f13eb5eaf2b0d086ef ;;
    kokoro-multi-lang-v1_1) echo b78e1ac42b852e839cceaafbe88f66806bf5860992d1d7b9a3f2ad1198427aed ;;
    *) echo "" ;;
  esac
}

fetch_model() {
  model="$1"
  if [ -f "$model/.complete" ]; then
    echo "Already present: $model"
    return
  fi
  echo "Downloading $model"
  download "$model.tar.bz2" "$base/tts-models/$model.tar.bz2"
  digest="$(digest_for "$model")"
  if [ -n "$digest" ]; then
    printf '%s  %s\n' "$digest" "$model.tar.bz2" | sha256sum -c -
  fi
  python3 -c 'import sys, tarfile; tarfile.open(sys.argv[1]).extractall(".")' "$model.tar.bz2"
  test -d "$model"
  touch "$model/.complete"
  rm "$model.tar.bz2"
  echo "Ready: $model"
}

fetch_aux() {
  if [ ! -s vocos-16khz-univ.onnx ]; then
    download vocos-16khz-univ.onnx "$base/vocoder-models/vocos-16khz-univ.onnx"
  fi
}

fetch_model vits-melo-tts-zh_en & p1=$!
fetch_model matcha-icefall-zh-en & p2=$!
fetch_model kokoro-multi-lang-v1_1 & p3=$!
fetch_aux & p4=$!
wait "$p1"; wait "$p2"; wait "$p3"; wait "$p4"
