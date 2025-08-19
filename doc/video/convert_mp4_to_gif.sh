#!/usr/bin/env bash
# mp4_to_gif.sh — Convert all MP4 files in the current directory to GIFs.
# Dependencies: ffmpeg
set -euo pipefail

WIDTH=640         # 기본 가로폭(px)
FPS=12            # 기본 프레임레이트
OVERWRITE=0       # 기본은 기존 GIF 덮어쓰기 안 함 (-y로 덮어쓰기)
LOOP=0            # 0이면 무한 반복(loop), 1 이상이면 반복 횟수
START=""          # -s 00:00:02 형식 (옵션)
DURATION=""       # -t 5 혹은 -t 00:00:05 형식 (옵션)

usage() {
  cat <<'EOF'
사용법: ./mp4_to_gif.sh [옵션]

옵션:
  -w <width>     GIF 가로폭(px) 기본 640
  -p <fps>       프레임레이트 기본 12
  -l <loop>      반복 횟수 (0=무한, 기본 0)
  -s <start>     시작 지점(예: 00:00:02)
  -t <duration>  구간 길이(예: 5 또는 00:00:05)
  -y             기존 GIF가 있으면 덮어쓰기
  -h             도움말

예시:
  ./mp4_to_gif.sh -w 720 -p 10
  ./mp4_to_gif.sh -s 00:00:03 -t 4 -y
EOF
}

# ffmpeg 확인
command -v ffmpeg >/dev/null 2>&1 || { echo "에러: ffmpeg가 필요합니다."; exit 1; }

# 옵션 파싱
# 맨 앞의 ":"는 getopts의 에러 출력을 우리가 처리하겠다는 의미
while getopts ":w:p:l:s:t:yh" opt; do
  case "$opt" in
    w) WIDTH="$OPTARG" ;;
    p) FPS="$OPTARG" ;;
    l) LOOP="$OPTARG" ;;
    s) START="$OPTARG" ;;
    t) DURATION="$OPTARG" ;;
    y) OVERWRITE=1 ;;
    h) usage; exit 0 ;;
    \?) echo "알 수 없는 옵션: -$OPTARG"; usage; exit 1 ;;
    :)  echo "옵션 -$OPTARG 에 값이 필요합니다."; usage; exit 1 ;;
  esac
done

shopt -s nullglob nocaseglob

# MP4 파일 수집
mp4s=( *.mp4 )
if [ ${#mp4s[@]} -eq 0 ]; then
  echo "현재 디렉토리에 mp4 파일이 없습니다."
  exit 0
fi

echo "변환 시작: WIDTH=${WIDTH}, FPS=${FPS}, LOOP=${LOOP}${START:+, START=${START}}${DURATION:+, DURATION=${DURATION}}"

for src in "${mp4s[@]}"; do
  base="${src%.*}"
  dst="${base}.gif"

  if [ -e "$dst" ] && [ $OVERWRITE -eq 0 ]; then
    echo "[SKIP] $dst 가 이미 존재합니다. (-y로 덮어쓰기)"
    continue
  fi

  palette="$(mktemp -t palette-XXXXXXXX.png)"

  # 1단계: 팔레트 생성
  gen_cmd=(ffmpeg -y -hide_banner -loglevel error)
  [[ -n "$START" ]] && gen_cmd+=(-ss "$START")
  [[ -n "$DURATION" ]] && gen_cmd+=(-t "$DURATION")
  gen_cmd+=(-i "$src" -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen=stats_mode=full" "$palette")

  # 2단계: 팔레트 적용하여 GIF 생성
  use_cmd=(ffmpeg -y -hide_banner -loglevel error)
  [[ -n "$START" ]] && use_cmd+=(-ss "$START")
  [[ -n "$DURATION" ]] && use_cmd+=(-t "$DURATION")
  use_cmd+=(-i "$src" -i "$palette" -lavfi "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,paletteuse=dither=bayer:bayer_scale=5" -loop "$LOOP" "$dst")

  echo "[MAKE] $src -> $dst"
  "${gen_cmd[@]}"
  "${use_cmd[@]}"

  rm -f "$palette"
  echo "[DONE] $dst"
done

echo "모든 변환이 완료되었습니다."
