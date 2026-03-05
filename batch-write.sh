#!/bin/bash
# 소설 배치 집필 스크립트 (템플릿)
#
# Claude Code의 claude -p 를 반복 호출하여 소설을 자동으로 집필한다.
# 매 배치마다 CLAUDE.md의 전체 워크플로(집필 → 리뷰 → 교정 → 커밋)를 수행한다.
#
# === 사용 전 설정 ===
# 아래 변수들을 본인 소설에 맞게 수정하세요.
# 또는 Claude Code에게 "batch-write.sh를 내 소설에 맞게 수정해줘"라고 요청하세요.
#
# === 사용법 ===
#   bash batch-write.sh                  # 전체 범위 실행
#   bash batch-write.sh 50 100           # 50~100화만 실행
#   nohup bash batch-write.sh &          # 백그라운드 실행 (터미널 종료해도 유지)
#   nohup bash batch-write.sh 50 100 &   # 백그라운드 + 범위 지정

set -euo pipefail

# === 소설별 설정 (수정 필요) ===
NOVEL_ID="no-title-XXX"                    # 소설 폴더명
PROJECT_DIR="/root/novel"                  # 프로젝트 루트
NOVEL_DIR="${PROJECT_DIR}/${NOVEL_ID}"
BATCH_SIZE=5                               # 배치당 화수 (권장: 5)
DEFAULT_START=1                            # 시작 화수
DEFAULT_END=100                            # 종료 화수

# 아크 구성 (소설 구조에 맞게 수정)
# get_arc 함수: 화수 → 아크명 매핑
get_arc() {
    local ep=$1
    if [ "$ep" -le 6 ]; then echo "prologue"
    elif [ "$ep" -le 100 ]; then echo "arc-01"
    elif [ "$ep" -le 200 ]; then echo "arc-02"
    elif [ "$ep" -le 300 ]; then echo "arc-03"
    elif [ "$ep" -le 400 ]; then echo "arc-04"
    fi
}

# 아크 전환 화수 목록 (부 종료 시 점검 트리거)
ARC_BOUNDARIES=(100 200 300 400)

# gemini-feedback 포함 여부 (Gemini CLI 미설치 시 false)
USE_GEMINI=true
# ================================================

# 중첩 세션 방지 우회 (Claude Code 세션 내에서 실행 시 필요)
unset CLAUDECODE 2>/dev/null || true

LOG_FILE="${PROJECT_DIR}/batch-write-${NOVEL_ID}.log"
START=${1:-$DEFAULT_START}
END=${2:-$DEFAULT_END}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== 배치 집필 시작: ${NOVEL_ID} ${START}화 ~ ${END}화 ==="

for (( batch_start=START; batch_start<=END; batch_start+=BATCH_SIZE )); do
    batch_end=$((batch_start + BATCH_SIZE - 1))
    if [ "$batch_end" -gt "$END" ]; then
        batch_end=$END
    fi

    arc=$(get_arc "$batch_start")
    arc_file="${NOVEL_DIR}/plot/${arc}.md"

    log "--- 배치 ${batch_start}~${batch_end}화 (${arc}) 시작 ---"

    # 플롯 파일이 없으면 자동 생성
    if [ ! -f "$arc_file" ]; then
        log "${arc}.md 플롯 생성 중..."
        cd "$PROJECT_DIR" && claude -p \
"${NOVEL_ID} 소설의 ${arc} 상세 플롯을 작성해줘.

작성 규칙:
1. 이전 아크 플롯 파일의 형식을 따라 작성
2. plot/master-outline.md의 해당 아크 개요를 따라감
3. 직전 아크 종료 상태(summaries/running-context.md)를 이어받음
4. 10화 블록 상세 포함
5. 캐릭터 아크, 복선 계획, 주요 전투/이벤트 목록 포함
6. 결과를 ${NOVEL_ID}/plot/${arc}.md에 저장

CLAUDE.md의 모든 규칙을 준수한다." >> "$LOG_FILE" 2>&1

        if [ ! -f "$arc_file" ]; then
            log "ERROR: ${arc}.md 생성 실패. 스크립트 중단."
            exit 1
        fi
        log "${arc}.md 생성 완료"
    fi

    # gemini-feedback 지시문
    if [ "$USE_GEMINI" = true ]; then
        GEMINI_INSTRUCTION="7. gemini-feedback 에이전트를 반드시 실행한다 (gemini CLI로 편집 리뷰 -> 피드백 반영 -> 한글 교정 순서)."
    else
        GEMINI_INSTRUCTION="7. gemini-feedback은 건너뛴다 (Gemini CLI 미설치)."
    fi

    # 배치 집필 프롬프트
    PROMPT="${NOVEL_ID} 소설 ${batch_start}~${batch_end}화를 순차 집필해줘.

[집필 지시]
1. CLAUDE.md의 집필 워크플로를 매 화마다 빠짐없이 따른다.
2. plot/${arc}.md의 해당 화수 플롯을 따라간다.
3. 직전 에피소드부터 이어서 쓴다 (summaries/running-context.md 참조).
4. CLAUDE.md에 정의된 화당 분량을 준수하고, 매 화 엔딩 훅 필수.
5. 요약 파일을 매 화 갱신한다.
6. config.json에 새 에피소드 등록 + totalEpisodes 업데이트.
${GEMINI_INSTRUCTION}
8. 매 화 완료 후 커밋한다.
9. 에러 발생 시 해당 화에서 멈추고 상황을 로그에 남긴다."

    # 정기 점검 (BATCH_SIZE 화 배수)
    if (( batch_end % BATCH_SIZE == 0 )); then
        PROMPT="${PROMPT}
10. ${batch_end}화 완료 후 CLAUDE.md의 정기 점검 항목을 수행한다."
    fi

    # 아크 전환 점검
    for boundary in "${ARC_BOUNDARIES[@]}"; do
        if [ "$batch_start" -le "$boundary" ] && [ "$batch_end" -ge "$boundary" ]; then
            PROMPT="${PROMPT}
11. ${boundary}화(아크 종료) 완료 후 아크 종료 점검을 수행한다: 아크 전체 요약, 목표 달성도, running-context 대정리."
        fi
    done

    log "claude 실행 중 (${batch_start}~${batch_end}화)..."

    if cd "$PROJECT_DIR" && claude -p "$PROMPT" >> "$LOG_FILE" 2>&1; then
        log "배치 ${batch_start}~${batch_end}화 완료"
    else
        EXIT_CODE=$?
        log "ERROR: 배치 ${batch_start}~${batch_end}화 실패 (exit code: ${EXIT_CODE})"
        log "재시작: bash batch-write.sh $((batch_start)) ${END}"
        exit 1
    fi

    # 진행률
    completed=$((batch_end - START + 1))
    total=$((END - START + 1))
    pct=$((completed * 100 / total))
    log "진행률: ${completed}/${total}화 (${pct}%)"

    # 배치 간 대기 (API rate limit 방지)
    if [ "$batch_end" -lt "$END" ]; then
        sleep 10
    fi
done

log "=== 전체 집필 완료: ${NOVEL_ID} ${START}화 ~ ${END}화 ==="
