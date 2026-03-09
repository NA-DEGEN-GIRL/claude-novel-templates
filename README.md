# Claude Novel Templates

AI(Claude Code)로 웹소설을 쓰기 위한 프로젝트 템플릿.

설정, 연속성 추적, 품질 검토, 외부 AI 편집까지 — 소설 집필의 전체 파이프라인을 자동화한다.

---

## 개요

이 템플릿은 Claude Code의 [Custom Agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents) 기능을 활용하여 웹소설 집필 워크플로우를 자동화한다.

**"N화 작성해줘"** 한 마디로:

```
맥락 로딩 → 장면 구성 → 본문 집필 → 자체 검토 → 한글 교정
→ 연속성 검증 → 요약 갱신 → Gemini 편집 리뷰 → 커밋
```

이 전체 과정이 하나의 파이프라인으로 실행된다.

### 주요 기능

- **12개 전문 에이전트**: 집필, 품질 검토, 연속성 검증, 한글 교정, 전수 감사, 정밀 검증, 감사 수정 등
- **연속성 자동 추적**: 캐릭터 상태, 관계, 정보 보유 현황, 약속/복선을 파일로 관리
- **외부 AI 편집**: Gemini CLI / NIM Proxy / Ollama 다중 소스 검토 (Claude가 쓰고, 외부 AI가 편집)
- **삽화 자동 생성**: NovelAI 연동, 캐릭터 외모 일관성 자동 보장
- **한자 표기 추적**: 첫 등장 시 한글(漢字) 병기, 이후 자동 생략
- **병렬 집필 지원**: 여러 에이전트가 동시에 다른 화를 쓰고, 사후 정합성 점검
- **전수 감사**: `/audit`으로 전 에피소드 연속성·품질·한글 일괄 검증, `/audit-fix`로 보고서 기반 자동 수정

---

## 필수 환경

| 도구 | 용도 | 설치 |
|------|------|------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | 집필 에이전트 실행 | `npm install -g @anthropic-ai/claude-code` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | 외부 AI 편집자 1순위 (선택) | `npm install -g @google/gemini-cli` |
| [NIM Proxy](https://github.com/NA-DEGEN-GIRL/nim-proxy) | 외부 AI 편집자 fallback (선택) | 아래 참조 |

### 외부 AI 편집자 (선택)

집필 후 외부 AI가 원고를 편집 리뷰한다. **둘 다 없어도 집필은 진행된다.**

| 순위 | 도구 | 특징 |
|------|------|------|
| 1순위 | **Gemini CLI** | 파일 시스템을 직접 탐색하여 설정·맥락을 자동 참조. 리뷰 품질 최고 |
| 2순위 | **NIM Proxy** | 독립 리뷰 소스. NVIDIA NIM API를 통해 오픈소스 모델(Mistral Large 3 등) 활용. 무료 |

**NIM Proxy 설치:**

```bash
git clone https://github.com/NA-DEGEN-GIRL/nim-proxy.git
cd nim-proxy
pip install -r requirements.txt  # 또는 uv pip install .
cp .env.example .env
# .env에 NVIDIA_API_KEY 설정 (https://build.nvidia.com 에서 무료 발급)
python server.py  # localhost:8082에서 실행
```

> NIM/Ollama는 Gemini와 독립된 리뷰 소스다. CLAUDE.md의 플래그(`nim_feedback`, `ollama_feedback`)로 활성화한다. Gemini 실패 시 NIM으로 fallback하지 않고, 건너뛴 뒤 다음 묶음 검토(P7, 5화마다)에서 재시도한다.

### MCP 서버 (선택)

수치 계산과 한자 검증의 정확도를 높이려면 아래 MCP 서버를 설치한다.

| MCP 서버 | 용도 | 레포 |
|----------|------|------|
| **novel-calc** | 날짜 계산, 전통 단위 변환, 화폐 계산, 이동 시간 추정 등 | [mcp-novel-calc](https://github.com/NA-DEGEN-GIRL/mcp-novel-calc) |
| **novel-hanja** | 한자어 검색, 검증, 작명 보조 | [mcp-novel-hanja](https://github.com/NA-DEGEN-GIRL/mcp-novel-hanja) |
| **novel-editor** | 외부 AI(Gemini/NIM/Ollama) 편집 리뷰 오케스트레이션 | [mcp-novel-editor](https://github.com/NA-DEGEN-GIRL/mcp-novel-editor) |
| **novelai-image** | 캐릭터/삽화/표지 이미지 자동 생성 (NovelAI API) | [mcp-novelai-image](https://github.com/NA-DEGEN-GIRL/mcp-novelai-image) |

MCP 서버 없이도 템플릿 자체는 동작한다. 다만 AI가 수치와 한자를 자체 추론하게 되므로 정확도가 떨어질 수 있다.

---

## 빠른 시작

### 1. 템플릿 복사

```bash
# 레포 클론
git clone https://github.com/NA-DEGEN-GIRL/claude-novel-templates.git

# 새 소설 폴더에 복사
NEW_ID="my-novel"
mkdir -p $NEW_ID
cp -r claude-novel-templates/{CLAUDE.md,SETUP-GUIDE.md,settings,summaries,chapters,plot} $NEW_ID/
mkdir -p $NEW_ID/.claude/agents
cp -r claude-novel-templates/.claude/* $NEW_ID/.claude/
```

### 2. 초기 셋업

AI에게 맡기는 것을 권장한다. [INIT-PROMPT.md](./INIT-PROMPT.md)에 4가지 셋업 프롬프트가 준비되어 있다.

| 프롬프트 | 설명 | 적합한 상황 |
|----------|------|-------------|
| **시나리오 선택형** | 장르+키워드 → 3개 시나리오 제안 → 선택 → 전체 셋업 | 아이디어가 막연할 때 |
| **컨셉 확정형** | 제목+주인공+컨셉 제공 → 캐릭터/플롯 제안 → 전체 셋업 | 쓸 소설이 정해졌을 때 |
| **풀 자동** | 장르만 던지면 전부 자동 결정 | 빠른 테스트 |
| **기존 소설 복제** | 원본 설정 복사 + 모델/작성자 변경 | 모델 비교 실험 |

```bash
cd my-novel && claude
# INIT-PROMPT.md에서 원하는 프롬프트를 복사하여 붙여넣기
```

> 수동으로 직접 셋업하려면 [SETUP-GUIDE.md](./SETUP-GUIDE.md)를 참조한다.

<details>
<summary>수동 셋업 시 해야 할 것</summary>

**권한 설정** — `settings.local.json`은 `claude -p`(배치 실행)에 필수다:

```bash
cp $NEW_ID/.claude/settings.local.example.json $NEW_ID/.claude/settings.local.json
```

**CLAUDE.md 커스터마이징** — `{{PLACEHOLDER}}`를 실제 값으로 채운다:

| Placeholder | 설명 | 예시 |
|-------------|------|------|
| `{{NOVEL_TITLE}}` | 소설 제목 | 천외귀환 |
| `{{NOVEL_ID}}` | 폴더명 | my-novel |
| `{{GENRE}}` | 장르 | 무협 회귀물 |
| `{{TONE}}` | 톤앤무드 | 진지+유머 7:3 |
| `{{TARGET_LENGTH}}` | 에피소드 목표 분량 | 4000~6000자 |
| `{{PROMISE_1~3}}` | 작품의 핵심 약속 | |

**세계관·캐릭터 설정** — `settings/` 폴더의 파일들을 작성한다:

```
settings/
├── 01-style-guide.md         ← 문체, 시점, 유머 비율
├── 02-episode-structure.md   ← 에피소드 구조 (5막)
├── 03-characters.md          ← 캐릭터 시트
├── 04-worldbuilding.md       ← 세계관 규칙
└── 05-continuity.md          ← 연속성 관리 (EPISODE_META 형식)
```

</details>

### 3. 집필 시작 (감독자 방식 권장)

셋업 완료 후 **감독자 방식**으로 집필을 시작한다. 감독자가 tmux 세션을 통해 집필 AI를 자동으로 모니터링하고, 에러 복구·질문 응답·다음 화 전송까지 처리한다.

```bash
# 상위 폴더에서 감독자 실행
cd /root/novel && claude
# → "my-novel/batch-supervisor.md 대로 수행"
```

> 한 화씩 직접 쓰려면 소설 폴더에서 `cd my-novel && claude` → `"1화 작성해줘"`.
> 감독자 방식의 상세 설정은 아래 [배치 자동 집필](#배치-자동-집필) 섹션을 참조한다.

---

## 프로젝트 구조

```
my-novel/
├── CLAUDE.md                  ← 집필 헌법 (최상위 규칙)
├── SETUP-GUIDE.md             ← 수동 셋업 가이드
├── INIT-PROMPT.md             ← AI 셋업 프롬프트 (4종)
├── batch-write.sh             ← 배치 자동 집필 스크립트
├── batch-supervisor.md        ← 배치 집필 감독 프롬프트 (tmux 방식)
├── batch-supervisor-audit.md  ← 배치 감사 감독 프롬프트 (tmux 방식)
├── settings/                  ← 세계관·캐릭터·규칙
│   ├── 01-style-guide.md
│   ├── 02-episode-structure.md
│   ├── 03-characters.md
│   ├── 04-worldbuilding.md
│   ├── 05-continuity.md
│   ├── 07-periodic.md          병렬 집필 & 정기 점검
│   └── 08-illustration.md      표지·삽화 규칙
├── chapters/                  ← 에피소드 원고
│   ├── prologue/
│   └── arc-01/
├── plot/                      ← 플롯·복선 관리
├── summaries/                 ← 연속성 추적 파일
│   ├── hanja-glossary.md          한자 표기 용어집
│   ├── knowledge-map.md           캐릭터 정보 보유 현황
│   ├── promise-tracker.md         약속·복선 추적
│   ├── relationship-log.md        만남·관계 로그
│   ├── editor-feedback-log.md     에디터 피드백 처리 로그
│   ├── illustration-log.md        삽화 기록
│   └── arc-summaries/             아크 요약 보관
└── .claude/
    ├── settings.local.json         ← Claude Code 권한 설정 (gitignore 대상)
    ├── settings.local.example.json ← 권한 설정 예시 (복사하여 사용)
    ├── commands/              ← 스킬 커맨드 (슬래시 명령)
    │   ├── audit.md               /audit — 전수 감사
    │   ├── audit-fix.md           /audit-fix — 감사 수정
    │   └── audit-verify.md        /audit-verify — 정밀 검증
    └── agents/                ← 전문 에이전트 12종
        ├── writer.md
        ├── reviewer.md
        ├── continuity-checker.md
        ├── korean-proofreader.md
        ├── gemini-feedback.md
        ├── plot-planner.md
        ├── summary-generator.md
        ├── summary-validator.md
        ├── illustration-manager.md
        ├── full-audit.md              전수 감사 에이전트
        ├── audit-fixer.md             감사 수정 에이전트
        └── audit-verifier.md          정밀 검증 에이전트
```

---

## 전체 워크플로우

### Phase 1: 프로젝트 셋업

[INIT-PROMPT.md](./INIT-PROMPT.md)의 프롬프트를 사용하거나, 수동으로 [SETUP-GUIDE.md](./SETUP-GUIDE.md)를 따른다.

```
셋업 결과물:
my-novel/
├── CLAUDE.md              ← 집필 헌법 (모든 규칙의 최상위)
├── settings/              ← 세계관, 캐릭터, 문체, 구조 규칙
├── plot/                  ← 전체 아크 + 복선 설계
├── chapters/              ← 빈 아크 폴더
├── summaries/             ← 빈 추적 파일들
├── batch-supervisor.md    ← 배치 자동 집필 설정
└── .claude/agents/        ← 12개 전문 에이전트
```

셋업만 수행한다. **에피소드 집필은 Phase 2에서 별도로 시작.**

### Phase 2: 집필 시작

두 가지 방법 중 택 1. **감독자 방식을 권장한다.**

```bash
# 방법 A: 감독자 배치 (권장 — 자동 연속 집필)
cd /root/novel && claude
# → "my-novel/batch-supervisor.md 대로 수행"

# 방법 B: 직접 집필 (한 화씩)
cd my-novel && claude
# → "1화 작성해줘"
```

감독자 방식에서는 감독자와 집필자의 역할이 분리된다:

```
집필자 (소설 폴더)              감독자 (상위 폴더)
──────────────────           ──────────────────
CLAUDE.md 규칙 준수            tmux 세션 모니터링
본문 집필 + 리뷰               에러 복구, 질문 답변
요약 파일 갱신                  config.json 에피소드 등록
EPISODE_META 삽입              /clear 주기 관리
git commit                    다음 화 프롬프트 전송
```

### Phase 3: 에피소드 1화 파이프라인

`"N화 작성해줘"` 한 마디로 writer 에이전트가 전체를 자동 수행한다.

```
A. 사전 준비 (Prep)
│  running-context.md     ← 현재 맥락
│  plot/ 아크 파일        ← 이번 화 목표
│  foreshadowing.md       ← 복선 투하/회수 확인
│  character-tracker.md   ← 캐릭터 상태
│  promise-tracker.md     ← 미이행 약속
│  knowledge-map.md       ← 정보 보유 현황
│  relationship-log.md    ← 만남/관계 이력
│  EDITOR_FEEDBACK        ← 미처리 피드백 확인
│
├─────────────────────────────────────
│
B. 장면 구성 (Plan)
│  비트시트 작성 (3~5 장면)
│  등장인물, 핵심 이벤트, 엔딩 훅 설계
│
├─────────────────────────────────────
│
C. 본문 집필 (Write)
│  에피소드 구조 + 문체 가이드 준수
│  목표 분량 (소설별 설정, 보통 3000~6000자)
│  수치/날짜 → novel-calc MCP (필요 시 검증용)
│  한자 작명 → novel-hanja MCP
│
├─────────────────────────────────────
│
D. 요약 갱신 (Post) — 7개 파일
│  episode-log.md         ← 1줄 요약
│  running-context.md     ← 현재 맥락 (200줄 이내)
│  character-tracker.md   ← 변경된 캐릭터만
│  promise-tracker.md     ← 약속 추가/진전/완료
│  knowledge-map.md       ← 정보 습득/전파
│  relationship-log.md    ← 만남/관계 변화
│  foreshadowing.md       ← 복선 상태
│
├─────────────────────────────────────
│
E. 리뷰 & 수정 (Review) — 건너뛰지 않는다
│
│  ┌─ reviewer (7항목 5점) ────────────┐
│  ├─ gemini-feedback (외부 AI 편집) ──┤ 병렬
│  └─ continuity-checker (13항목) ─────┘
│          ↓
│     수정 반영 (오류/높음 항목)
│          ↓
│     korean-proofreader (8항목)  ← 반드시 마지막
│          ↓
│     수정 있으면 D단계 요약 재갱신
│
├─────────────────────────────────────
│
F. 마무리
│  EPISODE_META 삽입 (date = 오늘)
│  피드백 로그 갱신 (반영/참고/건너뜀)
│  git commit (본문 + 요약 함께)
│
└─ 완료 → 다음 화로
```

### Phase 4: 정기 점검 (5화마다)

에피소드 단위로 못 잡는 **누적 드리프트**를 방지한다.

| # | 항목 | 방법 |
|---|------|------|
| P1 | 요약 정합성 | summary-validator 일괄 감사 |
| P2 | 복선 회수 시한 | 회수 예정 시점 지난 복선 확인 |
| P3 | 캐릭터 상태 최신성 | character-tracker ↔ 최신 에피소드 대조 |
| P4 | 성격 드리프트 | 최근 5화 대사/행동 ↔ 캐릭터 시트 |
| P5 | 미이행 약속 | 시한 경과/방치된 약속 확인 |
| P6 | running-context | 200줄 이내, 최신 반영 확인 |
| P7 | 외부 AI 일괄 리뷰 | gemini-feedback 배치 모드 |
| P8 | 한글 품질 | AI 습관 단어/반복 패턴 일괄 교정 |
| P9 | 메타 참조 금지 | "X화에서" 등 전수 검사 |

### Phase 5: 아크 전환

```
아크 종료 시:
  → 아크 요약 작성 (summaries/arc-summaries/)
  → 아크 목표 달성도 검토
  → running-context.md 대정리 (아크 내용 → 아크 요약으로 이관)
  → 다음 아크 plot 파일 생성 (plot-planner 에이전트)
  → 정기 점검 수행 (5화 미만이어도)
```

### Phase 6: 전수 감사 (수시)

집필 후 누적된 오류를 일괄 점검하고 수정한다. 정기 점검(Phase 4)이 5화 단위 예방이라면, 전수 감사는 **전체 또는 범위 지정 정밀 검증**이다.

```
/audit              ← 전 에피소드 감사 (읽기 전용, 본문 수정 없음)
/audit 1-30         ← 범위 지정 감사
/audit --resume     ← 중단된 감사 재개

    ↓ 보고서 생성: summaries/full-audit-report.md

/audit-verify          ← 크리티컬 항목 2차 정밀 검증 (선택)
/audit-verify --all    ← 전체 ❌/⚠️ 검증
/audit-verify --critical ← ❌ 연속성만 최소 검증

    ↓ 검증 보고서: summaries/full-audit-verify.md

/audit-fix          ← 보고서 기반 자동 수정 (verify 있으면 참조)
/audit-fix 10-20    ← 범위 지정 수정
/audit-fix --resume ← 중단된 수정 재개
```

**감사 파이프라인:**

```
1. /audit 실행 (1차 감사 — 어떤 모델이든)
   │  설정 파일 + summaries 전체 로딩
   │  1화부터 순차 읽기 (10화 배치, 병렬 금지)
   │  연속성(13항목) + 품질(4항목) + 한글교정(9항목) 동시 탐지
   │  → summaries/full-audit-report.md (보고서)
   │  → summaries/full-audit-tracker.md (누적 추적)
   │
2. /audit-verify 실행 (선택 — 1차와 다른 모델 권장)
   │  크리티컬/불확실 항목만 선별 (EPISODE_META 제외)
   │  6종 판정: 확인/상향/하향/수정확인/기각/미결
   │  → summaries/full-audit-verify.md
   │
3. /audit-fix 실행
   │  verify 있으면 참조 (기각→스킵, 상향→우선, 수정확인→보정안 사용)
   │  보고서의 ❌/⚠️ 항목 처리 (💡 참고는 무시)
   │  수정 순서: 연속성 → 품질 → 한글교정 → 최종교정
   │  → 본문 수정 + 요약 파일 갱신 + tracker에 이력 추가
```

**범위 감사 모드:**

| 모드 | 조건 | 특징 |
|------|------|------|
| 정밀 | tracker에 이전 감사 데이터 존재 | 누적 데이터(캐릭터 상태, 복선 등) 활용 |
| 부트스트랩 | tracker 없음 | summaries 기반 맥락 추정, 확인 불가 항목은 ⚠️ 처리 |

**배치 감사 감독** (`batch-supervisor-audit.md`):

대량 감사를 자동화하려면 배치 감사 감독을 사용한다. Claude Code가 tmux 세션을 감독하며 N화 단위로 `/audit` → `/clear` → `/audit --resume`을 반복한다.

| 설정 | 의미 | 적합한 모델 |
|------|------|-------------|
| `BATCH_SIZE=-1` | 전체를 한 번에 감사 (auto-compact 사용) | Claude Code |
| `BATCH_SIZE=10` | 10화씩 끊어서 감사 + `/clear` 반복 | GLM-5, Qwen 등 (auto-compact 없음) |

```bash
cd /root/novel && claude
# → "batch-supervisor-audit.md 대로 수행"
```

---

### 에이전트 12종

| 에이전트 | 역할 | 호출 시점 |
|----------|------|-----------|
| **writer** | 전체 파이프라인 자동 수행 | `"N화 작성해줘"` |
| **reviewer** | 7항목 5점 루브릭 품질 채점 | writer가 자동 호출 |
| **continuity-checker** | 13항목 연속성 검증 (위치, 부상, 시간선, 말투, 고유명사 등) | writer가 자동 호출 |
| **korean-proofreader** | 8항목 한글 교정 (맞춤법, 번역투, AI 습관 단어) | writer가 자동 호출 |
| **gemini-feedback** | 외부 AI 편집 리뷰 (Gemini CLI / NIM / Ollama) → 반영/참고/건너뜀 판단 | writer가 자동 호출 |
| **plot-planner** | 아크 플롯 설계, 비트시트, 복선 타이밍 | 새 아크 시작 전 |
| **summary-generator** | 요약 7종 파일 정밀 갱신 | writer 후처리 |
| **summary-validator** | 요약↔원문 대조 검증 | 5화마다 정기 점검 |
| **illustration-manager** | 삽화 검증, 일괄 감사, 재생성 | 삽화 삽입 후 |
| **full-audit** | 전 에피소드 연속성+품질+한글 일괄 검증 (읽기 전용) | `/audit` |
| **audit-fixer** | 감사 보고서 기반 자동 수정 (연속성→품질→한글 순) | `/audit-fix` |
| **audit-verifier** | 크리티컬/불확실 항목 2차 정밀 검증 (오탐 제거) | `/audit-verify` |

### 파일 참조 우선순위

설정이 충돌할 경우 위가 이긴다:

```
1. CLAUDE.md       (집필 헌법)
2. settings/       (세부 규칙)
3. 이전 에피소드    (확립된 사실)
4. summaries/      (참고용)
```

---

## 연속성 추적 시스템

AI가 100화 넘게 써도 캐릭터 상태, 관계, 복선을 잊지 않도록 파일로 추적한다.

| 파일 | 추적 대상 | 예시 |
|------|-----------|------|
| `knowledge-map.md` | 캐릭터별 정보 보유 현황 | "A는 B의 정체를 모른다" |
| `promise-tracker.md` | 약속·계획·복선 | "10화에서 한 약속, 20화까지 회수 예정" |
| `relationship-log.md` | 캐릭터 간 만남·관계 변화 | "A↔B: 첫 만남(3화), 적대→협력(15화)" |
| `hanja-glossary.md` | 한자 병기 첫 등장 추적 | "내공(內功): 1화 첫 등장 → 이후 '내공'만 표기" |
| `illustration-log.md` | 삽화 프롬프트·생성 기록 | 캐릭터 외모 일관성 유지용 |

이 파일들은 writer가 집필 전에 자동으로 읽고, 집필 후에 자동으로 갱신한다.

---

## 외부 AI 편집자 연동

Claude가 쓴 원고를 외부 AI가 편집 리뷰한다. 편집 지시문(GEMINI.md)은 `novel-editor` MCP 서버에 번들되어 자동 적용된다.

### 동작 방식

`novel-editor` MCP 서버가 설치되어 있으면, `gemini-feedback` 에이전트가 단일 MCP 도구 호출로 전체 파이프라인을 실행한다:

```
writer 집필 완료
  │
  └─ gemini-feedback 에이전트
       │
       └─ review_episode() MCP 호출
            │
            ├─ Phase 1: NIM + Ollama (병렬, 플래그에 따라)
            │     └─ EDITOR_FEEDBACK_nim.md / _ollama.md 저장
            │
            ├─ Phase 2: Gemini CLI (NIM/Ollama 결과 참고)
            │     └─ 성공 → EDITOR_FEEDBACK_gemini.md 저장
            │     └─ 실패 → 건너뛰고 다음 묶음 검토(P7)에서 재시도
            │
            └─ Claude가 피드백 평가 → 반영 / 참고 / 건너뜀
```

1. writer가 집필 완료 후 `gemini-feedback` 에이전트를 호출
2. 에이전트가 `review_episode` MCP 도구를 호출 (NIM/Ollama/Gemini 전체 오케스트레이션)
3. CLAUDE.md의 플래그(`nim_feedback`, `ollama_feedback`)에 따라 활성 소스 자동 결정
4. Gemini 실패 시 fallback 없이 건너뛰고, 다음 묶음 검토(P7, 5화마다)에서 재리뷰
5. Claude가 피드백을 평가하여 반영/참고/건너뜀 결정
6. `CLAUDE.md`(소설 규칙)와 충돌하는 제안은 자동으로 건너뜀

> MCP 서버 없이도 Bash 명령으로 직접 호출하는 방식이 가능하지만, 오픈소스 모델(NIM Proxy 기반)이 집필 AI인 경우 복잡한 Bash 구성을 건너뛸 수 있다. MCP 도구는 모든 AI 모델이 안정적으로 호출하므로 구조적으로 더 안정적이다.

### 외부 AI가 체크하는 것

- 한국어 자연스러움 (번역투, 어색한 표현)
- 시대 부적합 용어 (무협에서 '시스템', '패턴' 등 외래어)
- 연속성·논리 오류
- 캐릭터 말투 일관성
- 삽화 추천 장면 선정

### Gemini vs NIM Proxy 차이

| | Gemini CLI | NIM Proxy |
|---|-----------|-----------|
| 파일 탐색 | 직접 파일 시스템 접근 | 프롬프트에 설정 포함 필요 |
| 설치 | `npm install -g @google/gemini-cli` | `git clone` + `.env` 설정 |
| 비용 | Google AI 무료 티어 | NVIDIA NIM 무료 티어 |
| 모델 | Gemini | Mistral Large 3, Qwen 등 선택 가능 |
| 품질 | 최고 (전체 맥락 자동 참조) | 우수 (주요 설정만 프롬프트에 포함) |

> 둘 다 없어도 집필 파이프라인은 정상 동작한다. 외부 리뷰 단계만 건너뛴다.

---

## MCP 도구

수치 검증이 필요할 때 MCP 서버로 정확한 계산을 보장한다. 서사 흐름이 우선이며, calc 결과를 본문에 직접 넣지 않는다.

### novel-calc ([레포](https://github.com/NA-DEGEN-GIRL/mcp-novel-calc))

| 도구 | 용도 |
|------|------|
| `date_calc`, `d_plus`, `date_diff` | 날짜·요일 계산 |
| `unit_convert` | 전통 단위 변환 (리, 장, 척, 근, 시진 등) |
| `convert_time` | 십이지시 ↔ 현대 시각 |
| `currency_calc` | 화폐 계산 (냥, 전, 푼) |
| `travel_estimate` | 이동 시간 추정 |
| `supply_calc` | 군량·보급 계산 |
| `char_count` | 글자 수 확인 |

### novel-hanja ([레포](https://github.com/NA-DEGEN-GIRL/mcp-novel-hanja))

| 도구 | 용도 |
|------|------|
| `hanja_lookup` | 한자 → 음/훈/획수 분석 |
| `hanja_search` | 한글 음으로 한자 검색 |
| `hanja_meaning` | 의미 키워드로 한자 탐색 |
| `hanja_verify` | 한자어 존재 여부 + 소설 내 중복 체크 |

### novel-editor ([레포](https://github.com/NA-DEGEN-GIRL/mcp-novel-editor))

외부 AI(Gemini CLI, NIM Proxy, Ollama)를 MCP 도구로 호출하여 편집 리뷰를 오케스트레이션한다. AI가 복잡한 Bash 명령을 구성하는 대신, 단일 MCP 호출로 NIM/Ollama 병렬 실행 → Gemini 순차 실행까지 처리한다.

| 도구 | 용도 |
|------|------|
| `review_episode` | 단건 에피소드 편집 리뷰 (NIM+Ollama 병렬 -> Gemini 순차) |
| `batch_review` | 여러 에피소드 일괄 리뷰 (범위 또는 파일 목록) |
| `check_status` | 외부 AI 서비스 상태 확인 |

> 특히 NIM Proxy 기반 오픈소스 모델을 집필 AI로 사용할 때 유용하다. 오픈소스 모델은 복잡한 Bash 명령(curl + jq + 파이프라인)을 건너뛰는 경향이 있지만, MCP 도구는 안정적으로 호출한다.

### novelai-image ([레포](https://github.com/NA-DEGEN-GIRL/mcp-novelai-image))

NovelAI API로 캐릭터/삽화/표지를 자동 생성한다. `character-prompts.md`에서 캐릭터 태그를 자동 로드하여 외모 일관성을 보장한다.

| 도구 | 용도 |
|------|------|
| `list_characters` | 캐릭터 목록 조회 |
| `generate_character` | 캐릭터 초상화 생성 |
| `generate_image` | 범용 이미지 생성 |
| `generate_illustration` | 에피소드 삽화 생성 (다인물 좌표 배치) |
| `generate_cover` | 소설 표지 생성 |

---

## 배치 자동 집필

수십~수백 화를 **자동으로 연속 집필**하는 두 가지 방식을 제공한다. **감독자 방식을 권장한다.**

| 방식 | 파일 | 특징 | 적합한 상황 |
|------|------|------|-------------|
| **감독자 방식** (권장) | `batch-supervisor.md` | Claude Code가 tmux 화면을 읽고 AI 상태를 판단. 에러 복구, 질문 응답, 다음 화 전송 자동 처리 | 대부분의 상황 |
| **스크립트 방식** | `batch-write.sh` | `claude -p`를 5화 단위 반복. 백그라운드 실행 가능 | NIM 프록시 모델, 무인 장시간 배치 |

두 방식 모두 소설 폴더 안에 파일을 두고, **요약 파일(running-context, character-tracker 등)을 통해 맥락을 이어받는다**.

### 감독자 방식의 장점

- **맥락적 상태 판단**: bash 스크립트는 파일 존재 여부와 타임아웃으로만 판단하지만, 감독자는 AI의 실제 상태(작업 중, 에러, 질문, 완료 등)를 맥락적으로 이해한다
- **에러 자동 복구**: 원인을 분석하고 적절한 조치를 취한다 (재시도, /clear, 세션 재시작 등)
- **질문 응답**: 집필 AI가 질문하면 감독자가 판단하여 답변한다
- **config.json 관리**: 감독자가 상위 폴더에서 에피소드 등록을 처리하므로, 집필 AI는 본문 집필에만 집중한다
- **유연한 모델 선택**: `WRITER_CMD`로 집필 모델을 자유롭게 지정 (Claude, NIM 프록시 경유 모델 등)

---

### 방식 1: 감독자 (`batch-supervisor.md`)

Claude Code가 또 다른 Claude Code의 tmux 세션을 주기적으로 확인하며 집필을 감독한다.

#### 실행 구조

```
/root/novel/                    <- 감독자 Claude Code (상위 폴더)
├── no-title-XXX/               <- 집필자 Claude Code (tmux 세션)
│   ├── batch-supervisor.md     <- 감독 규칙
│   └── CLAUDE.md               <- 집필 헌법 (집필자가 자동 로드)
```

- **감독자**: 상위 폴더(`/root/novel/`)에서 Claude Code를 열고 프롬프트를 입력
- **집필자**: tmux 세션 안에서 소설 폴더로 이동하여 `claude` 실행

감독자가 상위 폴더에 있으므로 config.json 관리 등 전체 맥락을 파악하고, 집필자는 소설 폴더의 CLAUDE.md를 자동 로드하여 해당 소설의 규칙을 정확히 따른다.

#### 사용법

```bash
# 1. batch-supervisor.md를 소설에 맞게 편집 (아크 매핑, 범위 등)
# 2. 상위 폴더에서 감독자 실행
cd /root/novel && claude
# 3. batch-supervisor.md의 프롬프트를 붙여넣기
```

#### 설정 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `NOVEL_ID` | 소설 폴더명 | — |
| `SESSION` | tmux 세션명 | `write-{ID}` |
| `WRITER_CMD` | 집필자 실행 명령 | `claude` |
| `CHUNK_SIZE` | /clear 주기 | `10` |
| `ARC_MAP` | 아크-화수 매핑 | 소설별 설정 |

`WRITER_CMD`로 집필 모델을 지정할 수 있다:
- `claude` — 기본 Claude Code
- `claude --model claude-sonnet-4-6` — 특정 모델
- `claude --model gpt-oss:120b` — NIM 프록시 경유 모델

#### 감독자가 감지하는 상태 (9가지)

| 상태 | 조치 |
|------|------|
| 작업 중 | 2분 후 재확인 |
| 자동 압축 | 정상 동작, 2분 후 재확인 |
| 질문하며 멈춤 | 답변 전송 |
| 권한 요청 | 승인 전송 |
| 에러 발생 | 원인 분석 후 복구 |
| MCP 연결 실패 | 재연결 시도 |
| 무한 루프 | /clear 후 재시작 |
| 완료 | 다음 화 프롬프트 전송 |
| 비정상 종료 | 세션 재시작 |

완료 판정은 3중 확인: 프롬프트 대기 + 파일 존재 + batch-progress.log 기록.

자세한 내용은 [batch-supervisor.md](./batch-supervisor.md)를 참조한다.

---

### 방식 2: 스크립트 (`batch-write.sh`)

`claude -p`를 5화 단위로 반복 호출한다. 각 배치는 독립된 세션에서 실행된다. 감독자 없이 무인 실행이 가능하지만, 에러 발생 시 해당 배치에서 멈추고 수동 재시작이 필요하다.

> **NIM Proxy + 스크립트 조합**: 오픈소스 모델은 compact가 불안정할 수 있는데, 스크립트 방식은 5화마다 새 세션을 시작하므로 이 문제를 구조적으로 우회한다. NIM Proxy 기반으로 수백 화 연속 집필 시 적합하다.

#### 각 배치에서 하는 일

매 화마다 CLAUDE.md에 정의된 전체 워크플로를 수행한다:

```
사전 읽기 → 개요 → 초고 → 자가 검증 → 요약 갱신 → EPISODE_META
→ 에이전트 리뷰 (continuity-checker + reviewer + gemini-feedback)
→ 수정 반영 + 한글 교정 → 피드백 로그 → 커밋
```

#### 설치

`batch-write.sh`를 소설 폴더 안에 복사한다. 소설 폴더에서 실행해야 `.claude/agents/`가 자동으로 로드된다.

```bash
cp batch-write.sh my-novel/batch-write.sh
```

#### 권한 설정 (중요)

`claude -p`(비대화형 모드)에서는 도구 사용 시 **사용자 승인을 받을 수 없다**. `.claude/settings.local.json`에 필요한 도구를 미리 허용해야 배치가 정상 동작한다.

템플릿의 `.claude/settings.local.json`에는 기본 권한이 포함되어 있다:

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "mcp__novel-calc__*",
      "mcp__novel-hanja__*",
      "mcp__novel-editor__*",
      "mcp__novelai-image__generate_image",
      "mcp__novelai-image__generate_character",
      "mcp__novelai-image__list_characters",
      "mcp__novelai-image__generate_illustration",
      "mcp__novelai-image__generate_cover"
    ]
  }
}
```

> **`Edit(*)`, `Glob(*)`, `Grep(*)`가 빠지면 배치가 실패한다.** `claude -p`가 에러를 발생시키지만 exit code 0을 반환하여, 로그에는 "완료"로 표시되면서 실제 파일은 생성되지 않는 현상이 발생한다. 배치 스크립트에 파일 생성 검증 로직이 포함되어 있으므로, 이 경우 `ERROR: claude 성공 반환이나 파일 미생성` 메시지와 함께 중단된다.

NIM Proxy를 메인 집필 AI로 사용하는 경우, `env` 섹션을 추가한다:

```json
{
  "permissions": { "allow": ["..."] },
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8082",
    "ANTHROPIC_AUTH_TOKEN": "dummy-token",
    "ANTHROPIC_API_KEY": "",
    "API_TIMEOUT_MS": "600000"
  }
}
```

#### 변수 커스터마이징

스크립트 상단의 변수를 본인 소설에 맞게 수정한다. **직접 수정하거나**, Claude Code에게 맡길 수 있다:

```
batch-write.sh를 내 소설에 맞게 수정해줘.
CLAUDE.md와 plot/ 구조를 참고해서 아크 매핑, 시작/종료 화수,
아크 전환 지점을 자동으로 설정해.
```

수정이 필요한 변수:

| 변수 | 설명 | 예시 |
|------|------|------|
| `DEFAULT_START` / `DEFAULT_END` | 기본 집필 범위 | `1` / `400` |
| `get_arc()` | 화수 → 아크명 매핑 함수 | 소설 구조에 따라 |
| `ARC_BOUNDARIES` | 아크 종료 화수 (종료 점검 트리거) | `(100 200 300)` |
| `USE_EXTERNAL_FEEDBACK` | 외부 AI 피드백 에이전트 사용 여부 (Gemini/NIM/Ollama) | `true` / `false` |

#### 실행

```bash
cd my-novel

# 전체 범위 실행
bash batch-write.sh

# 특정 범위만
bash batch-write.sh 50 100

# 백그라운드 실행 (터미널 닫아도 계속)
nohup bash batch-write.sh &

# 실패 후 이어가기 (로그에서 마지막 성공 지점 확인)
bash batch-write.sh 73 200
```

#### 모니터링

```bash
# 진행 상황 확인
tail -20 my-novel/batch-write.log

# 실시간 모니터링
tail -f my-novel/batch-write.log

# 중단
kill $(pgrep -f batch-write)
```

---

## 장르별 참고

### 무협/판타지

- `04-worldbuilding.md`에 파워 시스템 상세히 정의
- 현대 단위(cm, km, kg) 대신 전통 단위 사용 → `unit_convert`로 변환
- 영어 외래어(시스템, 패턴, 에너지) → 한자어·고유어로 대체

### 현대물/로맨스

- SNS/채팅 포맷을 `01-style-guide.md`에 정의
- 실존 브랜드·장소 패러디 규칙 정의

### SF/미스터리

- `04-worldbuilding.md`에 기술 규칙 엄격히 정의
- 정보 공개 순서를 별도로 관리
- 복선 추적에 더 많은 비중

---

## 커스터마이징 체크리스트

1. [ ] `CLAUDE.md` — `{{PLACEHOLDER}}` 모두 채우기
2. [ ] `settings/01-style-guide.md` — 문체·시점·유머 비율
3. [ ] `settings/02-episode-structure.md` — 에피소드 구조·분량
4. [ ] `settings/03-characters.md` — 주요 캐릭터 시트 (최소 주인공 + 2~3명)
5. [ ] `settings/04-worldbuilding.md` — 세계관 핵심 규칙
6. [ ] `settings/05-continuity.md` — EPISODE_META 형식 커스터마이징
7. [ ] `CLAUDE.md` 섹션 8 — 호칭/어투 매트릭스 작성
8. [ ] (선택) `settings/06-humor-guide.md` — 러닝 개그 등록
9. [ ] (선택) `mcp-novel-editor/GEMINI.md` — 장르별 편집 지침 커스터마이징 (MCP 서버 번들)

---

## 라이선스

MIT License
