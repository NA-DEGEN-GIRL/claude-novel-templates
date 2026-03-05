#!/bin/bash
# 소설 배치 집필 스크립트 (템플릿)
#
# 이 파일을 소설 폴더 안에 두고 실행한다.
# Claude Code의 claude -p 를 반복 호출하여 소설을 자동으로 집필한다.
# 매 배치마다 CLAUDE.md의 전체 워크플로(집필 → 리뷰 → 교정 → 커밋)를 수행한다.
#
# === 설치 위치 ===
#   no-title-XXX/batch-write.sh   ← 소설 폴더 안에 둔다
#
# === 사용 전 설정 ===
# 아래 변수들을 본인 소설에 맞게 수정하세요.
# 또는 Claude Code에게 "batch-write.sh를 내 소설에 맞게 수정해줘"라고 요청하세요.
#
# === 사용법 ===
#   cd no-title-XXX && bash batch-write.sh                  # 전체 범위
#   cd no-title-XXX && bash batch-write.sh 50 100           # 50~100화만
#   cd no-title-XXX && nohup bash batch-write.sh &          # 백그라운드
#   cd no-title-XXX && nohup bash batch-write.sh 50 100 &   # 백그라운드 + 범위

set -euo pipefail

# 중첩 세션 방지 우회 (Claude Code 세션 내에서 실행 시 필요)
unset CLAUDECODE 2>/dev/null || true

# === 소설별 설정 (수정 필요) ===
BATCH_SIZE=5                               # 배치당 화수 (권장: 3~5)
DEFAULT_START=1                            # 시작 화수
DEFAULT_END=100                            # 종료 화수
CHECKPOINT_INTERVAL=5                      # 정기 점검 주기 (CLAUDE.md 기본값: 5화)

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

# 외부 AI 피드백 에이전트 사용 여부
# true: gemini-feedback 에이전트 실행 (Gemini CLI / NIM / Ollama 오케스트레이션)
# false: 외부 피드백 건너뜀 (continuity-checker, reviewer, korean-proofreader는 여전히 실행)
USE_EXTERNAL_FEEDBACK=true
# ================================================

# 소설 폴더 = 스크립트 위치 = CWD
NOVEL_DIR="$(cd "$(dirname "$0")" && pwd)"
NOVEL_NAME="$(basename "$NOVEL_DIR")"
LOG_FILE="${NOVEL_DIR}/batch-write.log"
DETAIL_LOG="${NOVEL_DIR}/batch-write-detail.log"

START=${1:-$DEFAULT_START}
END=${2:-$DEFAULT_END}
LAST_CHECKPOINT=$((START - 1))

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 소설 폴더에서 실행 (.claude/agents/ 자동 로드)
cd "$NOVEL_DIR"

log "=== 배치 집필 시작: ${NOVEL_NAME} ${START}화 ~ ${END}화 ==="
log "상세 로그: tail -f ${DETAIL_LOG}"

for (( batch_start=START; batch_start<=END; batch_start+=BATCH_SIZE )); do
    batch_end=$((batch_start + BATCH_SIZE - 1))
    if [ "$batch_end" -gt "$END" ]; then
        batch_end=$END
    fi

    arc=$(get_arc "$batch_start")
    arc_file="plot/${arc}.md"

    log "--- 배치 ${batch_start}~${batch_end}화 (${arc}) 시작 ---"

    # 플롯 파일이 없으면 자동 생성
    if [ ! -f "$arc_file" ]; then
        log "${arc}.md 플롯 생성 중..."
        claude -p \
"${arc} 상세 플롯을 작성해줘.

사전 읽기:
- CLAUDE.md (작품 개요, 구성)
- plot/ 폴더의 기존 아크 파일 (형식 참조)
- plot/master-outline.md (해당 아크 개요)
- summaries/running-context.md (직전 아크 종료 상태)

작성 규칙:
1. 기존 아크 플롯 파일과 동일한 형식으로 작성
2. master-outline.md의 해당 아크 개요를 따름
3. 10화 블록 상세 포함
4. 캐릭터 아크, 복선 계획, 주요 전투/이벤트 목록 포함
5. 결과를 plot/${arc}.md에 저장" >> "$LOG_FILE" 2>&1

        if [ ! -f "$arc_file" ]; then
            log "ERROR: ${arc}.md 생성 실패. 스크립트 중단."
            exit 1
        fi
        log "${arc}.md 생성 완료"
    fi

    # 외부 피드백 지시문
    if [ "$USE_EXTERNAL_FEEDBACK" = true ]; then
        FEEDBACK_INSTRUCTION="- gemini-feedback 에이전트를 포함하여 외부 AI 편집 리뷰도 수행한다."
    else
        FEEDBACK_INSTRUCTION="- gemini-feedback 에이전트는 건너뛴다. continuity-checker, reviewer, korean-proofreader는 정상 수행한다."
    fi

    # 배치 집필 프롬프트 — CLAUDE.md 워크플로에 위임하고 배치 고유 파라미터만 전달
    PROMPT="${batch_start}~${batch_end}화를 순차 집필해줘.

[배치 파라미터]
- 범위: ${batch_start}화 ~ ${batch_end}화
- 플롯: plot/${arc}.md 참조
- 1화를 완전히 완료(집필 + 리뷰 + 교정 + 요약 갱신 + 커밋)한 후 다음 화로 넘어간다.
- 각 화 집필 전 summaries/running-context.md를 다시 읽어 현재 상태를 확인한다. 이전 화 집필 시 메모리에 남은 내용에 의존하지 않는다.

[워크플로]
CLAUDE.md의 전체 워크플로(사전 준비 → 집필 → 자체 검토 → 연속성 검증 → 후처리 → 커밋)를 매 화마다 빠짐없이 따른다.
- 자체 검토 시 reviewer, continuity-checker, gemini-feedback 에이전트를 병렬 실행한다.
- 에이전트 리뷰 완료 후 korean-proofreader로 한글 교정을 수행한다.
${FEEDBACK_INSTRUCTION}

[에러 처리]
에러 발생 시 에러 내용을 stdout에 출력하고, 해당 화에서 작업을 중단한다."

    # 정기 점검: 직전 점검으로부터 CHECKPOINT_INTERVAL화 이상 경과 시
    episodes_since_checkpoint=$((batch_end - LAST_CHECKPOINT))
    if [ "$episodes_since_checkpoint" -ge "$CHECKPOINT_INTERVAL" ]; then
        PROMPT="${PROMPT}

[정기 점검]
${batch_end}화 완료 후, CLAUDE.md/settings/07-periodic.md의 정기 점검(P1~P9)을 수행한다."
        if [ "$USE_EXTERNAL_FEEDBACK" = true ]; then
            PROMPT="${PROMPT}
P7은 gemini-feedback 모드 B(일괄 리뷰)로 직전 점검 이후 에피소드를 대상으로 한다."
        fi
        LAST_CHECKPOINT=$batch_end
    fi

    # 아크 전환 점검
    for boundary in "${ARC_BOUNDARIES[@]}"; do
        if [ "$batch_start" -le "$boundary" ] && [ "$batch_end" -ge "$boundary" ]; then
            PROMPT="${PROMPT}

[아크 종료 점검]
${boundary}화(아크 종료) 완료 후:
1. 정기 점검(P1~P9)을 수행한다 (위에서 미수행 시).
2. 아크 전체 요약을 summaries/arc-summaries/에 작성한다.
3. 아크 목표 달성도를 검토한다.
4. running-context.md를 대정리한다 (해당 아크 내용을 아크 요약으로 이관)."
            LAST_CHECKPOINT=$boundary
        fi
    done

    log "claude 실행 중 (${batch_start}~${batch_end}화)..."
    echo "===== [$(date '+%H:%M:%S')] 배치 ${batch_start}~${batch_end}화 시작 =====" >> "$DETAIL_LOG"

    if stdbuf -oL claude -p --verbose --output-format stream-json "$PROMPT" | \
        jq --unbuffered -r '
        if .type == "assistant" then
          (.message.content[]? |
            if .type == "text" then "[" + (now | strftime("%H:%M:%S")) + "] 💬 " + .text
            elif .type == "tool_use" then "[" + (now | strftime("%H:%M:%S")) + "] 🔧 " + .name + " → " + (.input | tostring | .[0:120])
            else empty end)
        elif .type == "tool_result" then
          "  ↳ " + (.content | tostring | .[0:200])
        elif .type == "result" then
          "[" + (now | strftime("%H:%M:%S")) + "] ✅ 완료 (" + ((.duration_ms // 0) / 1000 | tostring) + "s, " + ((.total_cost_usd // 0) * 100 | round | tostring) + "¢)"
        else empty end
        ' >> "$DETAIL_LOG" 2>/dev/null; then
        # 실제 파일 생성 여부 검증 (claude -p가 exit 0이어도 내부 에러로 파일 미생성 가능)
        missing=()
        created=()
        for (( ep=batch_start; ep<=batch_end; ep++ )); do
            ep_arc=$(get_arc "$ep")
            ep_file="chapters/${ep_arc}/chapter-$(printf '%02d' "$ep").md"
            if [ ! -f "$ep_file" ]; then
                missing+=("${ep}화")
            else
                size=$(wc -c < "$ep_file")
                created+=("${ep}화(${size}b)")
            fi
        done
        if [ ${#missing[@]} -gt 0 ]; then
            log "ERROR: claude 성공 반환이나 파일 미생성: ${missing[*]}"
            log "재시작: cd ${NOVEL_DIR} && bash batch-write.sh $((batch_start)) ${END}"
            exit 1
        fi
        log "배치 ${batch_start}~${batch_end}화 완료: ${created[*]}"
    else
        EXIT_CODE=$?
        log "ERROR: 배치 ${batch_start}~${batch_end}화 실패 (exit code: ${EXIT_CODE})"
        log "재시작: cd ${NOVEL_DIR} && bash batch-write.sh $((batch_start)) ${END}"
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

log "=== 전체 집필 완료: ${NOVEL_NAME} ${START}화 ~ ${END}화 ==="
