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

- **9개 전문 에이전트**: 집필, 품질 검토, 연속성 검증, 한글 교정, 플롯 설계 등
- **연속성 자동 추적**: 캐릭터 상태, 관계, 정보 보유 현황, 약속/복선을 파일로 관리
- **외부 AI 편집**: Gemini CLI + NIM Proxy fallback으로 이중 검토 (Claude가 쓰고, 외부 AI가 편집)
- **삽화 자동 생성**: NovelAI 연동, 캐릭터 외모 일관성 자동 보장
- **한자 표기 추적**: 첫 등장 시 한글(漢字) 병기, 이후 자동 생략
- **병렬 집필 지원**: 여러 에이전트가 동시에 다른 화를 쓰고, 사후 정합성 점검

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
| 2순위 | **NIM Proxy** | Gemini 실패 시 자동 fallback. NVIDIA NIM API를 통해 오픈소스 모델(Mistral Large 3 등) 활용. 무료 |

**NIM Proxy 설치:**

```bash
git clone https://github.com/NA-DEGEN-GIRL/nim-proxy.git
cd nim-proxy
pip install -r requirements.txt  # 또는 uv pip install .
cp .env.example .env
# .env에 NVIDIA_API_KEY 설정 (https://build.nvidia.com 에서 무료 발급)
python server.py  # localhost:8082에서 실행
```

> Gemini CLI가 정상 동작하면 NIM Proxy는 호출되지 않는다. 인증 만료·네트워크 오류 등 Gemini 실패 시에만 자동으로 NIM에 fallback한다.

### MCP 서버 (선택)

수치 계산과 한자 검증의 정확도를 높이려면 아래 MCP 서버를 설치한다.

| MCP 서버 | 용도 | 레포 |
|----------|------|------|
| **novel-calc** | 날짜 계산, 전통 단위 변환, 화폐 계산, 이동 시간 추정 등 | [mcp-novel-calc](https://github.com/NA-DEGEN-GIRL/mcp-novel-calc) |
| **novel-hanja** | 한자어 검색, 검증, 작명 보조 | [mcp-novel-hanja](https://github.com/NA-DEGEN-GIRL/mcp-novel-hanja) |
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
cp -r claude-novel-templates/{CLAUDE.md,SETUP-GUIDE.md,GEMINI.md,settings,summaries,chapters,plot} $NEW_ID/
mkdir -p $NEW_ID/.claude/agents
cp -r claude-novel-templates/.claude/* $NEW_ID/.claude/
```

### 2. 설정 커스터마이징

`CLAUDE.md`의 `{{PLACEHOLDER}}`를 실제 값으로 채운다:

| Placeholder | 설명 | 예시 |
|-------------|------|------|
| `{{NOVEL_TITLE}}` | 소설 제목 | 천외귀환 |
| `{{NOVEL_ID}}` | 폴더명 | my-novel |
| `{{GENRE}}` | 장르 | 무협 회귀물 |
| `{{TONE}}` | 톤앤무드 | 진지+유머 7:3 |
| `{{TARGET_LENGTH}}` | 에피소드 목표 분량 | 4000~6000자 |
| `{{PROMISE_1~3}}` | 작품의 핵심 약속 | |

### 3. 세계관·캐릭터 설정

`settings/` 폴더의 파일들을 작성한다:

```
settings/
├── 01-style-guide.md         ← 문체, 시점, 유머 비율
├── 02-episode-structure.md   ← 에피소드 구조 (5막)
├── 03-characters.md          ← 캐릭터 시트
├── 04-worldbuilding.md       ← 세계관 규칙
└── 05-continuity.md          ← 연속성 관리 (EPISODE_META 형식)
```

> 각 파일에 가이드와 예시가 포함되어 있다. 자기 소설에 맞게 수정하면 된다.

### 4. 집필 시작

```bash
cd my-novel && claude
```

```
프롤로그 1화를 작성해줘.
```

writer 에이전트가 전체 파이프라인을 자동 수행한다.

---

## 또는: AI에게 맡기기

Claude Code 세션에서 아래처럼 지시하면 AI가 이 템플릿을 기반으로 전체 설정을 자동 생성한다:

```
templates/ 폴더를 참고해서 새 소설을 만들어줘.

- 제목: [소설 제목]
- 장르: [장르]
- 배경: [시대/세계관]
- 주인공: [이름, 간단 설명]
- 핵심 컨셉: [한줄 설명]
```

상세한 수동 셋업 절차는 [SETUP-GUIDE.md](./SETUP-GUIDE.md)를 참조한다.

---

## 프로젝트 구조

```
my-novel/
├── CLAUDE.md                  ← 집필 헌법 (최상위 규칙)
├── GEMINI.md                  ← Gemini 편집자 지시문
├── SETUP-GUIDE.md             ← 셋업 가이드
├── settings/                  ← 세계관·캐릭터·규칙
│   ├── 01-style-guide.md
│   ├── 02-episode-structure.md
│   ├── 03-characters.md
│   ├── 04-worldbuilding.md
│   └── 05-continuity.md
├── chapters/                  ← 에피소드 원고
│   ├── prologue/
│   └── arc-01/
├── plot/                      ← 플롯·복선 관리
├── summaries/                 ← 연속성 추적 파일
│   ├── hanja-glossary.md          한자 표기 용어집
│   ├── knowledge-map.md           캐릭터 정보 보유 현황
│   ├── promise-tracker.md         약속·복선 추적
│   ├── relationship-log.md        만남·관계 로그
│   ├── illustration-log.md        삽화 기록
│   └── arc-summaries/             아크 요약 보관
└── .claude/
    ├── settings.local.json    ← Claude Code 권한 설정
    └── agents/                ← 전문 에이전트 9종
        ├── writer.md
        ├── reviewer.md
        ├── continuity-checker.md
        ├── korean-proofreader.md
        ├── gemini-feedback.md
        ├── plot-planner.md
        ├── summary-generator.md
        ├── summary-validator.md
        └── illustration-manager.md
```

---

## 에이전트 파이프라인

### 자동 실행 흐름

`writer` 에이전트가 아래 전체 파이프라인을 자동 수행한다:

```
writer (전체 파이프라인)
  │
  ├─ [Prep]     맥락 로딩 (이전 화, 설정, 연속성 파일 8종)
  ├─ [Plan]     장면 구성 (비트시트 기반)
  ├─ [Write]    본문 집필 (MCP 도구로 수치·한자 검증)
  │
  ├─ [Review]   자체 검토 ──────────────────┐
  ├─ [Review]   외부 AI 편집 리뷰 ──────────┤ 병렬
  ├─ [Review]   연속성 검증 (13항목) ───────┤
  ├─ [Review]   한글 교정 (8항목) ──────────┘
  │
  ├─ [Fix]     오류·높음 항목 수정 → 재검토
  ├─ [Post]    요약 7종 갱신
  └─ [Commit]  git commit
```

### 에이전트 목록

| 에이전트 | 역할 | 호출 시점 |
|----------|------|-----------|
| **writer** | 전체 파이프라인 자동 수행 | `"N화 작성해줘"` |
| **reviewer** | 7항목 5점 루브릭 품질 채점 | writer가 자동 호출 |
| **continuity-checker** | 13항목 연속성 검증 (위치, 부상, 시간선, 말투, 고유명사 등) | writer가 자동 호출 |
| **korean-proofreader** | 8항목 한글 교정 (맞춤법, 번역투, AI 습관 단어) | writer가 자동 호출 |
| **gemini-feedback** | 외부 AI 편집 리뷰 (Gemini CLI / NIM Proxy fallback) → 반영/참고/건너뜀 판단 | writer가 자동 호출 |
| **plot-planner** | 아크 플롯 설계, 비트시트, 복선 타이밍 | 새 아크 시작 전 |
| **summary-generator** | 요약 7종 파일 정밀 갱신 | writer 후처리 |
| **summary-validator** | 요약↔원문 대조 검증 | 5화마다 정기 점검 |
| **illustration-manager** | 삽화 검증, 일괄 감사, 재생성 | 삽화 삽입 후 |

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

Claude가 쓴 원고를 외부 AI가 편집 리뷰한다. [GEMINI.md](./GEMINI.md)가 편집 지시문이다.

### 동작 방식

```
writer 집필 완료
  │
  ├─ Gemini CLI 호출 ─── 성공 → EDITOR_FEEDBACK.md 작성
  │                   └─ 실패 → NIM Proxy fallback
  │                                └─ 성공 → EDITOR_FEEDBACK.md 작성
  │                                └─ 실패 → 건너뜀 (집필은 계속)
  │
  └─ Claude가 피드백 평가 → 반영 / 참고 / 건너뜀
```

1. writer가 집필 완료 후 `gemini-feedback` 에이전트를 호출
2. **1순위**: Gemini CLI가 에피소드를 분석하고 `EDITOR_FEEDBACK.md`에 피드백 작성
3. **2순위**: Gemini 실패 시 NIM Proxy를 통해 Mistral Large 3 등 오픈소스 모델로 리뷰
4. Claude가 피드백을 평가하여 반영/참고/건너뜀 결정
5. `CLAUDE.md`(소설 규칙)와 충돌하는 제안은 자동으로 건너뜀

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

AI가 수치를 암산하면 틀린다. MCP 서버로 정확한 계산을 보장한다.

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

`batch-write.sh`를 사용하면 수십~수백 화를 **자동으로 연속 집필**할 수 있다.

### 원리

`claude -p`를 5화 단위로 반복 호출한다. 각 배치는 독립된 세션에서 실행되며, **요약 파일(running-context, character-tracker 등)을 통해 맥락을 이어받는다**. compact(컨텍스트 자동 압축)와 실질적으로 동일하지만, 실패 복구가 쉽고 백그라운드 실행이 가능하다.

### 각 배치에서 하는 일

매 화마다 CLAUDE.md에 정의된 전체 워크플로를 수행한다:

```
사전 읽기 → 개요 → 초고 → 자가 검증 → 요약 갱신 → EPISODE_META
→ 에이전트 리뷰 (continuity-checker + reviewer + gemini-feedback)
→ 수정 반영 + 한글 교정 → 피드백 로그 → config.json 등록 → 커밋
```

### 설정 방법

스크립트 상단의 변수를 본인 소설에 맞게 수정한다. **직접 수정하거나**, Claude Code에게 맡길 수 있다:

```
batch-write.sh를 내 소설에 맞게 수정해줘.
CLAUDE.md와 plot/ 구조를 참고해서 아크 매핑, 시작/종료 화수,
아크 전환 지점을 자동으로 설정해.
```

수정이 필요한 변수:

| 변수 | 설명 | 예시 |
|------|------|------|
| `NOVEL_ID` | 소설 폴더명 | `"no-title-001"` |
| `PROJECT_DIR` | 프로젝트 루트 경로 | `"/root/novel"` |
| `DEFAULT_START` / `DEFAULT_END` | 기본 집필 범위 | `1` / `400` |
| `get_arc()` | 화수 → 아크명 매핑 함수 | 소설 구조에 따라 |
| `ARC_BOUNDARIES` | 아크 종료 화수 (종료 점검 트리거) | `(100 200 300)` |
| `USE_GEMINI` | Gemini CLI 편집 리뷰 사용 여부 | `true` / `false` |

### 실행

```bash
# 전체 범위 실행
bash batch-write.sh

# 특정 범위만
bash batch-write.sh 50 100

# 백그라운드 실행 (터미널 닫아도 계속)
nohup bash batch-write.sh &

# 실패 후 이어가기 (로그에서 마지막 성공 지점 확인)
bash batch-write.sh 73 200
```

### 모니터링

```bash
# 진행 상황 확인
tail -20 batch-write-no-title-XXX.log

# 실시간 모니터링
tail -f batch-write-no-title-XXX.log

# 중단
kill $(pgrep -f batch-write)
```

### 자동 처리 포인트

- **플롯 자동 생성**: 해당 아크의 플롯 파일이 없으면 자동으로 생성한 뒤 집필 시작
- **정기 점검**: 5화마다 CLAUDE.md의 정기 점검 항목 수행 (요약 정합성, 복선 시한, 캐릭터 드리프트 등)
- **아크 전환 점검**: `ARC_BOUNDARIES`에 정의된 화수에서 아크 종료 점검 자동 수행
- **실패 복구**: 에러 발생 시 해당 배치에서 멈추고 로그에 재시작 명령어를 출력

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
7. [ ] `CLAUDE.md` 섹션 9 — 호칭/어투 매트릭스 작성
8. [ ] (선택) `settings/06-humor-guide.md` — 러닝 개그 등록
9. [ ] (선택) `GEMINI.md` — 장르별 편집 지침 추가

---

## 라이선스

MIT License
