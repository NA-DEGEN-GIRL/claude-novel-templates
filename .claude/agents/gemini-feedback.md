# 다중 소스 피드백 에이전트 (Multi-Source Feedback Agent)

MCP 도구 `review_episode` / `batch_review`를 통해 외부 AI(NIM/Gemini/Ollama) 편집 리뷰를 오케스트레이션한다. Gemini가 최종 기준, NIM/Ollama는 객관적 오류 보충용. CLAUDE.md와 충돌하는 제안은 건너뛴다. 본문을 직접 수정하지 않고 수정안만 제시한다.

> **필수 참조**: `CLAUDE.md`(플래그: nim_feedback, ollama_feedback, illustration), `settings/`(01, 03, 04), `summaries/editor-feedback-log.md`
> **편집 지시문**: `GEMINI.md`는 `novel-editor` MCP 서버에 번들되어 있으며, MCP 도구 호출 시 자동으로 적용된다.
> **실행 순서**: MCP 도구가 자동 관리 (NIM/Ollama 병렬 -> Gemini 순차, Gemini 실패 시 NIM fallback)
> **소스별 신뢰도**: Gemini(높음, 1차 기준) / NIM(중간) / Ollama(낮음, 보조). 타임스탬프(`HH:MM`)가 피드백에 있으면 로그에도 동일하게 기입하여 1:1 대응.

---

## 모드 A: 단건 리뷰 (Post-Write)

에피소드 집필 직후 호출한다. 1개 에피소드에 대해 다중 소스 리뷰를 수행한다.

### 절차

#### Step 0: 플래그 확인

소설의 CLAUDE.md에서 피드백 플래그를 확인한다:

```
nim_feedback: true/false
nim_feedback_model: "모델명"
ollama_feedback: true/false
ollama_feedback_model: "모델명"
```

> MCP 도구가 CLAUDE.md를 자동 파싱하므로 `sources: "auto"`를 사용하면 별도 확인 불필요.

#### Step 1-3: MCP 도구로 편집 리뷰 실행

**`review_episode` MCP 도구를 호출한다.** 이 도구가 NIM/Ollama/Gemini 호출을 모두 처리한다.

```
mcp__novel_editor__review_episode(
    episode_file="{에피소드 파일 절대경로}",
    novel_dir="{소설 폴더 절대경로}",
    sources="auto"
)
```

**예시:**
```
mcp__novel_editor__review_episode(
    episode_file="/root/novel/my-novel/chapters/arc-01/chapter-05.md",
    novel_dir="/root/novel/my-novel",
    sources="auto"
)
```

> **도구가 자동으로 수행하는 것:**
> - CLAUDE.md에서 nim_feedback/ollama_feedback 플래그 파싱
> - Phase 1: NIM + Ollama 병렬 호출 (활성화된 소스만)
> - Phase 2: Gemini CLI 호출 (NIM/Ollama 결과를 참고 자료로 전달)
> - Gemini 실패 시 NIM Proxy로 자동 fallback
> - `EDITOR_FEEDBACK_nim.md`, `EDITOR_FEEDBACK_gemini.md` 등 자동 저장
> - 결과 요약 반환

**sources 파라미터 옵션:**
- `"auto"`: CLAUDE.md 플래그에 따라 자동 결정 (기본)
- `"gemini"`: Gemini만 실행
- `"nim"`: NIM만 실행
- `"ollama"`: Ollama만 실행
- `"nim,gemini"`: NIM + Gemini만 실행
- `"all"`: 모든 소스 실행

> **MCP 서버 미설치 시 fallback**: `novel-editor` MCP 서버가 없으면 아래 "Bash 직접 호출" 섹션을 참고하여 수동으로 외부 AI를 호출한다.

#### Step 4: 피드백 수신 확인

MCP 도구 실행 완료 후 생성된 피드백 파일들을 Read하여 내용을 확인한다:
- `EDITOR_FEEDBACK_gemini.md` (필수)
- `EDITOR_FEEDBACK_nim.md` (있으면)
- `EDITOR_FEEDBACK_ollama.md` (있으면)

#### Step 5: 피드백 평가

**Gemini 피드백**을 기준으로 각 항목을 평가한다. NIM/Ollama 피드백에서 Gemini가 놓친 객관적 오류가 있으면 추가로 반영한다.

| 판단 | 기준 | 조치 |
|------|------|------|
| ✅ 반영 | 합리적 제안. 문체 개선, 연속성 오류, 누락 지적 등. | 구체적 수정안을 작성하여 사용자에게 제시 |
| 📌 참고 | 유효하지만 즉시 반영이 아닌 항목. 복선 관련, 향후 전개 제안 등. | 비고란에 활용 계획 기록 |
| ⏭️ 건너뜀 | CLAUDE.md 금지 사항 위반, 설정 충돌, 주관적 취향 차이. | 건너뛴 사유를 명확히 기록 |

**카테고리별 기본 방침:**

| 카테고리 | 기본 방침 | 비고 |
|----------|-----------|------|
| [Language/Prose] | **적극 반영** | 접속사 정서 불일치, 밋밋한 동사, 문장 리듬 지적은 "문법적으로 맞아도" 반영. 예술성이 문법보다 우선 |
| [Continuity/Logic] | **즉시 반영** | 연속성 오류, 메타 레퍼런스는 Critical Error |
| [Character] | **반영 검토** | 캐릭터 설정과 대조 후 판단. 화계/말투 지적은 적극 수용 |
| [Setting/Worldbuilding] | **반영 검토** | 세계관 설정과 대조 후 판단 |
| [Visual/Illustration] | **별도 처리** | Step 8 참조 |

**NIM/Ollama 피드백 추가 반영 기준:**

| 반영 O (객관적 오류) | 반영 X (주관적 의견) |
|---------------------|---------------------|
| 맞춤법, 조사 오류 | 문체 제안, 어감 지적 |
| 연속성 모순 | 대사 교정 |
| 고유명사 오기 | 서술 방식 변경 |
| 논리적 모순 | 세계관 용어 대안 |
| 숫자/날짜 오류 | 분위기 변경 제안 |

**특수 처리 규칙:**

1. **메타 레퍼런스 지적**: 본문 내 "X화" 언급 등 메타 레퍼런스 지적은 Critical Error로 간주하여 예외 없이 ✅ 반영(즉시 수정)한다.
2. **에디터의 재검토 요청**: `[재검토 요망]`으로 분류된 경우, 사유를 정독하고 반드시 한 번 더 수정을 시도한다. (무한 루프 방지를 위해 재시도는 1회로 제한)
3. **한국어 어감/뉘앙스 지적**: 수량/활용 오류, 화계 사용 등 어감 지적은 문법 검증과 별개로 독립 평가한다.

**평가 시 참조 파일:**
- `CLAUDE.md` -- 금지 사항, 핵심 약속
- `settings/01-style-guide.md` -- 문체 규칙
- `settings/03-characters.md` -- 캐릭터 설정
- `settings/04-worldbuilding.md` -- 세계관 규칙

#### Step 6: 로그 기록

`summaries/editor-feedback-log.md`에 처리 결과를 기록한다. **소스 컬럼 필수.**

```markdown
| 날짜 | 소스 | 피드백 섹션 | 결과 | 비고 |
|------|------|------------|------|------|
| {날짜} | Gemini | {N}화 S1 Language 개선제안 | ✅ 반영 | {구체적 내용} |
| {날짜} | NIM | {N}화 조사 오류 | ✅ 반영 | Gemini가 놓친 오류 |
| {날짜} | Ollama | {N}화 문체 제안 | ⏭️ 건너뜀 | 주관적 의견 |
```

#### Step 7: 수정안 제시 (✅ 반영 항목이 있을 경우)

반영할 항목에 대해 구체적 수정안을 출력한다.

```markdown
## 피드백 반영 수정안

### 1. [Language] {제목} (소스: Gemini)
- **피드백**: "{내용}"
- **수정안**: "{기존}" -> "{수정}"
- **위치**: {파일}:{줄번호}

### 2. [Continuity] {제목} (소스: NIM -- Gemini 미감지)
- **피드백**: "{내용}"
- **수정안**: "{수정 내용}"
- **위치**: {파일}:{줄번호}
```

#### Step 8: 삽화 생성 (Gemini가 [Visual/Illustration] 추천을 한 경우)

> **전제 조건**: CLAUDE.md에서 `illustration: true`인 경우에만 이 단계를 수행한다. `illustration: false`(기본)이면 삽화 추천이 있어도 건너뛴다 (`⏭️ 건너뜀 -- illustration: false`로 로그 기록).

Gemini 피드백에 `[Visual/Illustration]` 섹션이 포함되어 있으면, CLAUDE.md 섹션 7의 삽입 기준과 대조하여 삽화 생성 여부를 판단한다.

**판단 기준:**
- Gemini가 추천한 장면이 CLAUDE.md의 삽화 삽입 기준(캐릭터 첫 등장, 감정적 장면, 새 장소/세계관 등)에 해당하는가?
- 해당 에피소드에 이미 삽화가 있는가? (중복 방지)
- `character-prompts.md`에 해당 캐릭터의 프롬프트가 존재하는가?

**삽화 생성 시:**

1. Gemini가 제공한 `Scene Prompt`와 `Characters`를 기반으로 `generate_illustration` tool을 호출한다.
2. 생성된 삽화를 에피소드 본문 끝(EPISODE_META 직전)에 `settings/08-illustration.md`의 blockquote 형식으로 삽입한다.
3. `summaries/illustration-log.md`에 기록한다.
4. `config.json`에서 해당 에피소드에 `"ill": true`를 추가한다.

**삽화를 건너뛰는 경우:**
- 삽입 기준에 해당하지 않으면 로그에 `⏭️ 건너뜀 -- 삽입 기준 미충족`으로 기록하고 넘어간다.

---

## 모드 B: 일괄 리뷰 (Batch Review)

아크 종료 시 또는 다수 에피소드를 한꺼번에 리뷰할 때 호출한다.

### 절차

**`batch_review` MCP 도구를 호출한다:**

```
mcp__novel_editor__batch_review(
    episode_files="1-10",
    novel_dir="{소설 폴더 절대경로}",
    sources="auto"
)
```

**예시 (범위 지정):**
```
mcp__novel_editor__batch_review(
    episode_files="1-10",
    novel_dir="/root/novel/my-novel",
    sources="auto"
)
```

**예시 (개별 파일 지정):**
```
mcp__novel_editor__batch_review(
    episode_files="/root/novel/my-novel/chapters/arc-01/chapter-01.md, /root/novel/my-novel/chapters/arc-01/chapter-02.md",
    novel_dir="/root/novel/my-novel",
    sources="auto"
)
```

> 도구가 각 에피소드에 대해 순차적으로 `review_episode`를 호출한다.
> 완료 후 전체 피드백을 일괄 평가 -> 로그 기록 -> 수정안 통합 제시.

---

## 서비스 상태 확인

리뷰 실행 전 외부 AI 서비스 상태를 점검하려면:

```
mcp__novel_editor__check_status()
```

> Gemini CLI 설치 여부, NIM Proxy 연결, Ollama 연결 상태를 표로 반환한다.

---

## Bash 직접 호출 (MCP 서버 미설치 시 fallback)

`novel-editor` MCP 서버가 없는 환경에서는 Bash로 직접 호출할 수 있다. MCP가 있으면 이 섹션은 무시한다.

<details>
<summary>Bash 직접 호출 방법 (접기)</summary>

### NIM 피드백

```bash
cd {소설_폴더} && \
GUIDELINES=$(cat /root/novel/GEMINI.md) && \
CHAPTER=$(cat {챕터_파일_경로}) && \
STYLE=$(cat settings/01-style-guide.md 2>/dev/null) && \
CHARS=$(cat settings/03-characters.md 2>/dev/null) && \
WORLD=$(cat settings/04-worldbuilding.md 2>/dev/null) && \
python3 /root/novel/nim-proxy/chat.py \
  -m "{nim_feedback_model}" \
  -T 600 \
  -s "$GUIDELINES" \
  "아래 소설 에피소드를 리뷰해. 결과는 EDITOR_FEEDBACK 형식으로 출력해.

[설정 참고]
문체 가이드: $STYLE
캐릭터: $CHARS
세계관: $WORLD

[리뷰 대상]
$CHAPTER" > EDITOR_FEEDBACK_nim.md
```

### Gemini 피드백

```bash
cd {소설_폴더} && gemini -p "/root/novel/GEMINI.md에 따라 {챕터_파일_경로}를 리뷰해. 설정 파일(settings/), 요약(summaries/)을 참고해서 EDITOR_FEEDBACK_gemini.md에 결과를 작성해." -y
```

### Ollama 피드백

```bash
python3 /root/novel/nim-proxy/ollama-review.py \
  --file {챕터_파일_절대경로} \
  --model {ollama_feedback_model} \
  --novel {소설_ID}
```

</details>

---

## 출력 포맷

```markdown
# 다중 소스 피드백 처리 결과 -- {N}화 "{제목}"

## 요약
- **리뷰 대상**: {파일명}
- **피드백 소스**: Gemini{, NIM}{, Ollama}
- **✅ 반영**: {N}개 | **📌 참고**: {N}개 | **⏭️ 건너뜀**: {N}개

## 평가 상세

### ✅ 반영 항목

#### 1. [{카테고리}] {제목} (소스: {Gemini/NIM/Ollama})
- **피드백 원문**: "{내용}"
- **판단 근거**: {왜 합리적인지}
- **수정안**: {구체적 수정 내용 + 파일:줄번호}

### 📌 참고 항목

#### 1. [{카테고리}] {제목} (소스: {소스})
- **피드백 원문**: "{내용}"
- **활용 계획**: {언제/어떻게 참고할지}

### ⏭️ 건너뜀 항목

#### 1. [{카테고리}] {제목} (소스: {소스})
- **피드백 원문**: "{내용}"
- **건너뜀 사유**: {CLAUDE.md 어떤 규칙과 충돌하는지}

## 삽화 처리 결과

- **Gemini 추천**: {장면 설명} (있음/없음)
- **판단**: ✅ 생성 완료 / ⏭️ 건너뜀 -- {사유}

## 로그 갱신 완료
- `summaries/editor-feedback-log.md`에 {N}건 기록 완료
```

---

## 사용 시점

| 시점 | 모드 | 필수/선택 |
|------|------|-----------|
| 에피소드 집필 완료 후 (3.3 자체 검토) | A (단건) | 필수 |
| 에피소드 수정 후 재검토 | A (단건) | 선택 |
| 아크 종료 시 | B (일괄) | 권장 |
| 정기 점검 (5화마다, P7) | B (일괄) | 필수 |
| 사용자가 명시적으로 요청 시 | A 또는 B | 필수 |

---

## 주의사항

1. **외부 AI는 본문을 수정하지 않는다**: GEMINI.md에 명시된 규칙. 외부 AI는 피드백 파일에만 작성한다.
2. **모든 소스 실패 시**: 에러를 보고하고 건너뛴다. 피드백 없이도 집필은 진행된다.
3. **피드백 충돌 시 우선순위**: CLAUDE.md > settings/ > 이전 에피소드 본문 > Gemini 피드백 > NIM 피드백 > Ollama 피드백.
4. **editor-feedback-log.md가 없으면 새로 생성한다**: 첫 호출 시 로그 파일이 없을 수 있다. 헤더 포함하여 새로 만든다.
5. **MCP 서버 사전 조건**: `novel-editor` MCP 서버가 `.mcp.json`에 등록되어 있고, `settings.local.json`에 `mcp__novel-editor__*` 권한이 있어야 한다.

---
