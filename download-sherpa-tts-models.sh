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
    kokoro-multi-lang-v1_0) echo 60703707bc05ccd48d60e1eb723f38b07d6e474795a0b6a588d7220400e0f7a4 ;;
    kokoro-int8-multi-lang-v1_0) echo 72c347230107ef8a31098ec4d468a605244beef5f1ed00db97efa13518800653 ;;
    kokoro-multi-lang-v1_1) echo b78e1ac42b852e839cceaafbe88f66806bf5860992d1d7b9a3f2ad1198427aed ;;
    kokoro-int8-multi-lang-v1_1) echo 259c9c8bc906d6078e4e0570421885dabb68b539c2f970fcbb890a58eeaf3e9c ;;
    sherpa-onnx-zipvoice-distill-int8-zh-en-emilia) echo 77219c8b40f4ee8d73a7f902305ff6c1128ef9b54461c41b4ca6ed890b6c2803 ;;
    sherpa-onnx-zipvoice-distill-fp32-zh-en-emilia) echo 3b6729d03bf4ba64deeec113048bdbbe55dbc30580b609be76342e0099fd23a8 ;;
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
  for file in vocos-16khz-univ.onnx vocos_24khz.onnx; do
    if [ ! -s "$file" ]; then
      download "$file" "$base/vocoder-models/$file"
    fi
  done
  if [ ! -s lexicon-en-us.txt ]; then
    download lexicon-en-us.txt "$base/tts-models/lexicon-en-us.txt"
  fi
}

fetch_model vits-melo-tts-zh_en & p1=$!
fetch_model matcha-icefall-zh-en & p2=$!
fetch_model kokoro-int8-multi-lang-v1_0 & p3=$!
fetch_model kokoro-int8-multi-lang-v1_1 & p4=$!
fetch_aux & p5=$!
wait "$p1"; wait "$p2"; wait "$p3"; wait "$p4"; wait "$p5"

fetch_model kokoro-multi-lang-v1_0 & p1=$!
fetch_model kokoro-multi-lang-v1_1 & p2=$!
fetch_model sherpa-onnx-zipvoice-distill-int8-zh-en-emilia & p3=$!
fetch_model sherpa-onnx-zipvoice-distill-fp32-zh-en-emilia & p4=$!
wait "$p1"; wait "$p2"; wait "$p3"; wait "$p4"
