# 새 소설 프로젝트 셋업 가이드

> 이 가이드를 따라 새 소설 프로젝트를 생성한다.

---

## 빠른 시작

[INIT-PROMPT.md](./INIT-PROMPT.md)의 프롬프트를 사용하면 AI가 이 가이드의 절차를 자동으로 수행한다.

---

## 수동 셋업 절차

### Step 1: 폴더 생성

```bash
# 소설 ID 결정 (순번)
NEW_ID="no-title-003"

# 폴더 구조 생성
mkdir -p $NEW_ID/{settings,chapters/prologue,chapters/arc-01,plot,summaries/arc-summaries,.claude/agents}

# 템플릿 복사
cp claude-novel-templates/CLAUDE.md $NEW_ID/CLAUDE.md
cp claude-novel-templates/settings/*.md $NEW_ID/settings/
cp claude-novel-templates/.claude/agents/*.md $NEW_ID/.claude/agents/
cp claude-novel-templates/.claude/settings.local.example.json $NEW_ID/.claude/settings.local.json
```

### Step 2: CLAUDE.md 커스터마이징

`{{PLACEHOLDER}}`를 실제 값으로 채운다:

| Placeholder | 설명 | 예시 |
|-------------|------|------|
| `{{NOVEL_TITLE}}` | 소설 제목 | 천외귀환 |
| `{{NOVEL_ID}}` | 폴더명 | no-title-003 |
| `{{SUBTITLE}}` | 부제 (없으면 삭제) | |
| `{{GENRE}}` | 장르 | 무협 회귀물 |
| `{{TONE}}` | 톤앤무드 | 진지+유머 7:3 |
| `{{KEYWORDS}}` | 핵심 키워드 | 회귀, 복수, 성장 |
| `{{ONE_LINE_SUMMARY}}` | 한줄 소개 | |
| `{{TARGET_LENGTH}}` | 에피소드 목표 분량 | 4000~6000자 |
| `{{PROMISE_1~3}}` | 작품의 핵심 약속 | |

### Step 3: 설정 파일 작성

1. **01-style-guide.md**: 문체, 시점, 대화 규칙, 유머 비율
2. **02-episode-structure.md**: 에피소드 분량, 구조 비율 조정
3. **03-characters.md**: 주요 캐릭터 시트 작성 (최소 주인공 + 2~3명)
4. **04-worldbuilding.md**: 세계관 핵심 규칙, 장소, 조직
5. **05-continuity.md**: EPISODE_META 형식 커스터마이징

### Step 4: config.json 등록

`/root/novel/config.json`에 새 소설을 추가한다. 감독자 방식(`batch-supervisor.md`) 사용 시 감독자가 에피소드 등록을 자동 처리한다.

```json
{
  "id": "no-title-003",
  "title": "소설 제목",
  "subtitle": null,
  "author": "AI Writer",
  "genre": ["장르1", "장르2"],
  "description": "소설 소개",
  "cover": null,
  "status": "연재중",
  "totalEpisodes": 0,
  "parts": [
    {
      "name": "프롤로그",
      "scan": {
        "dir": "no-title-003/chapters/prologue",
        "pattern": "chapter-*.md",
        "numberExtract": "filename",
        "filenameRegex": "chapter-(\\d+)\\.md"
      },
      "episodes": []
    },
    {
      "name": "1부",
      "scan": {
        "dir": "no-title-003/chapters/arc-01",
        "pattern": "chapter-*.md",
        "numberExtract": "filename",
        "filenameRegex": "chapter-(\\d+)\\.md"
      },
      "episodes": []
    }
  ]
}
```

### Step 5: .gitignore / .vercelignore 업데이트

```
# .gitignore에 추가
no-title-003/

# .vercelignore에 추가
no-title-003/settings/
no-title-003/summaries/
no-title-003/.git/
no-title-003/.claude/
```

### Step 6: vercel.json 보안 설정 추가

```json
{ "source": "/no-title-003/settings/:path*", "destination": "/", "statusCode": 404 },
{ "source": "/no-title-003/summaries/:path*", "destination": "/", "statusCode": 404 }
```

### Step 7: Claude 에이전트 확인

`.claude/` 폴더에 아래 파일들이 정상적으로 복사되었는지 확인한다:

```
.claude/
├── settings.local.json              ← Claude Code 권한 설정
└── agents/
    ├── writer.md                    ← 집필 에이전트 (전체 파이프라인)
    ├── reviewer.md                  ← 품질 검토 에이전트 (7항목, 5점 루브릭)
    ├── continuity-checker.md        ← 연속성 검증 에이전트 (13항목)
    ├── korean-proofreader.md        ← 한글 교정 에이전트 (8항목)
    ├── gemini-feedback.md           ← 다중 소스 피드백 에이전트 (Gemini/NIM/Ollama)
    ├── plot-planner.md              ← 플롯 설계 에이전트
    ├── summary-generator.md         ← 요약 생성 에이전트 (7개 파일 갱신)
    ├── summary-validator.md         ← 요약 검증 에이전트 (원문 대조)
    └── illustration-manager.md      ← 삽화 관리 에이전트 (검증/감사/재생성)
```

**자동 실행 흐름:**
```
writer (전체 파이프라인)
  │
  ├─ [Prep]     맥락 로딩 (이전 화, 설정, 연속성 파일)
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

### Step 8: 표지 이미지 프롬프트 생성

소설의 장르, 분위기, 주인공 외형을 기반으로 NovelAI Image용 프롬프트를 작성하여 `cover-prompt.txt`에 저장한다.

```
{{NOVEL_ID}}/cover-prompt.txt
```

**프롬프트 작성 규칙:**

1. NovelAI Image는 Danbooru 태그 기반이다. 자연어가 아닌 **쉼표로 구분된 태그**로 작성한다.
2. 구조: `품질 태그, 구도, 인물 외형, 의상, 배경/분위기, 장르 연출`
3. 네거티브 프롬프트도 함께 작성한다.

**예시 (무협):**
```
[Prompt]
masterpiece, best quality, amazing quality,
1boy, solo, upper body, looking at viewer,
black hair, long hair, hair tied back, sharp eyes, serious expression,
hanfu, black robes, white inner robe, sword,
mountain landscape, mist, dramatic lighting, wind effect,
wuxia, martial arts, cinematic composition

[Negative Prompt]
lowres, bad anatomy, bad hands, text, error, missing fingers,
extra digit, fewer digits, cropped, worst quality, low quality,
normal quality, jpeg artifacts, signature, watermark, username, blurry
```

**예시 (현대물):**
```
[Prompt]
masterpiece, best quality, amazing quality,
1girl, solo, upper body, looking at smartphone,
blue hair, medium hair, casual outfit, hoodie,
city background, neon lights, night, modern,
social media aesthetic, dynamic angle

[Negative Prompt]
lowres, bad anatomy, bad hands, text, error, missing fingers,
extra digit, fewer digits, cropped, worst quality, low quality,
normal quality, jpeg artifacts, signature, watermark, username, blurry
```

표지는 writer 에이전트가 첫 에피소드 집필 시 자동 생성하거나, 사용자가 직접 생성할 수 있다.

### Step 9: batch-supervisor.md 설정 (선택)

배치 자동 집필을 사용하려면 `batch-supervisor.md`를 소설에 맞게 편집한다:
- `NOVEL_ID`, `SESSION`, `ARC_MAP` 등 설정 변수 수정
- `WRITER_CMD`로 집필 모델 지정 (기본: `claude`)

**셋업은 여기까지.** 이후 집필 시작은 아래 "셋업 후 집필 시작"을 참조한다.

---

## 셋업 후 집필 시작

셋업 완료 후, 집필은 별도 세션에서 시작한다:

### 방법 A: 직접 집필

```bash
cd /root/novel/no-title-003 && claude
# → "1화 작성해줘"
```

### 방법 B: 감독자로 배치 집필

```bash
cd /root/novel && claude
# → "no-title-003/batch-supervisor.md 대로 수행"
```

---

## 장르별 참고 사항

### 무협/판타지

- `04-worldbuilding.md`에 파워 시스템 상세히 정의
- `01-style-guide.md`에 한자어/고어체 사용 규칙 추가
- `06-humor-guide.md` 생성하여 러닝 개그 등록

### 현대물/로맨스

- `01-style-guide.md`에 SNS/채팅 포맷 정의
- 전문용어가 있으면 3단계 도입법(원어→설명→약어) 명시
- 실존 브랜드/장소 패러디 규칙 정의

### SF/미스터리

- `04-worldbuilding.md`에 기술 규칙 엄격히 정의
- `05-continuity.md`에서 복선 관리를 더 상세하게 운용
- 정보 공개 순서를 별도로 관리

---
