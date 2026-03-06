# 소설 초기 셋업 프롬프트

> `/root/novel/`(상위 폴더)에서 Claude Code를 열고 아래 프롬프트를 붙여넣는다.
> Claude가 시나리오를 제안하고, 선택 후 전체 프로젝트를 자동 생성한다.

---

## 사용법

```bash
cd /root/novel && claude
```

아래 프롬프트 중 하나를 선택하여 붙여넣는다.

---

## 프롬프트 1: 시나리오 선택형 (추천)

장르와 키워드만 주면 Claude가 3개 시나리오를 제안하고, 선택 후 전체 셋업을 수행한다.

```
claude-novel-templates/ 를 참고해서 새 소설 프로젝트를 만들어줘.

## 조건

- 장르: [장르] (예: 무협 회귀물, SF 스릴러, 현대 로맨스, 판타지)
- 톤: [톤앤무드] (예: 다크+감성 8:2, 진지+유머 7:3, 코미디 중심)
- 분량: [에피소드 목표 분량] (예: 4000~6000자)
- 총 화수: [목표 화수] (예: 70화, 200화)
- 특이사항: [있으면 적어줘] (예: 한자 병기 필요, 현대 배경이라 외래어 OK 등)

## 진행 방식

### 1단계: 시나리오 제안
위 조건으로 **서로 다른 컨셉의 시나리오 3개**를 제안해줘. 각 시나리오마다:
- 제목 + 한줄 소개
- 주인공 (이름, 한줄 설명)
- 핵심 갈등/컨셉
- 예상 아크 구성 (대략적)
- 차별점 (왜 이 시나리오가 재밌는지)

### 2단계: 선택 & 확장
내가 하나를 고르면 (또는 여러 개를 섞으라고 하면), 그걸로:
- 주요 캐릭터 3~5명 설계
- 아크별 대략적 플롯
- 핵심 약속 3가지
- 세계관 핵심 규칙

을 정리해서 보여줘. 내가 OK하면 3단계로.

### 3단계: 프로젝트 생성
claude-novel-templates/의 SETUP-GUIDE.md를 참조하여 아래 체크리스트대로 전체 파일을 생성해줘:

1. 소설 폴더 생성 (no-title-XXX, 다음 번호 자동 결정)
2. 템플릿 파일 복사 (CLAUDE.md, settings/, agents/, summaries/ 등)
3. CLAUDE.md의 {{PLACEHOLDER}} 전부 채우기
4. settings/ 파일 전부 실제 내용으로 작성
5. plot/master-outline.md 작성 (전체 아크 구성)
6. plot/foreshadowing.md 초기 복선 설계
7. plot/arc-01.md 작성 (1아크 상세 플롯)
8. summaries/ 초기 파일 생성 (빈 템플릿)
9. batch-supervisor.md 생성 (아크 매핑, 화수 범위 설정)
10. config.json에 새 소설 등록 (totalEpisodes: 0, parts 구조)
11. .gitignore, vercel.json 보안 설정 추가

**에피소드 집필은 하지 않는다. 파일 생성 후 4단계 검증으로 넘어간다.**

### 4단계: 교차 검증
생성된 설정 파일들을 에이전트 3팀으로 병렬 검증한다. 모순이 발견되면 즉시 수정한다.

**팀 A (사실 관계 대조):**
- 캐릭터 능력/출신이 세계관에 존재하는가 (03-characters ↔ 04-worldbuilding)
- 플롯이 요구하는 역할을 수행할 캐릭터가 있는가 (master-outline ↔ 03-characters)
- 호칭 매트릭스가 캐릭터 관계와 일치하는가 (CLAUDE.md 8.1 ↔ 03-characters)
- 복선 설치/회수 시점이 아크 구성과 정합하는가 (foreshadowing ↔ master-outline)
- CLAUDE.md 연속성 항목과 continuity-checker.md 항목이 일치하는가

**팀 B (서사 실현성):**
- 핵심 약속 3가지가 아크 구성으로 실현 가능한가 (CLAUDE.md 1.1 ↔ master-outline)
- 플롯이 금지 사항을 위반하지 않는가 (CLAUDE.md 5 ↔ master-outline)
- CLAUDE.md의 분량 목표와 episode-structure/writer.md의 분량이 일치하는가
- reviewer.md가 소설 고유 톤/장르를 반영하는가

**팀 C (표기/일관성):**
- 문체/단위/외래어 규칙이 세계관 시대 배경과 맞는가 (01-style-guide ↔ 04-worldbuilding)
- 07-periodic.md 항목 수가 CLAUDE.md 참조와 일치하는가
- illustration 플래그가 관련 파일들과 일치하는가
- EPISODE_META 고유 필드가 continuity 설정에 반영되었는가

검증 완료 후 모순 0건이면 5단계로.

### 5단계: git commit (2단계)
셋업은 /root/novel/ 에서 실행되므로 두 곳에 각각 커밋한다.

**5-A: 소설 폴더 독립 레포 생성**
소설 폴더는 상위 레포의 .gitignore로 제외되어 있으므로 독립 git 레포로 초기화한다.
```bash
cd no-title-XXX && git init && git add -A && git commit -m "프로젝트 초기 셋업"
```

**5-B: 상위 레포에 등록 커밋**
상위 레포에서는 config.json, vercel.json, .gitignore만 커밋한다.
```bash
cd /root/novel && git add config.json vercel.json .gitignore && git commit -m "소설명(no-title-XXX) 등록"
```

**주의: 에피소드 집필은 하지 않는다. 프로젝트 셋업(설정 파일 생성 + 검증)까지만 수행.**
```

---

## 프롬프트 2: 컨셉 확정형

이미 쓰고 싶은 소설이 정해져 있을 때. 바로 셋업으로 진행한다.

```
claude-novel-templates/ 를 참고해서 새 소설 프로젝트를 만들어줘.

## 소설 정보

- 제목: [제목]
- 부제: [부제 또는 없음]
- 장르: [장르]
- 톤: [톤앤무드]
- 한줄 소개: [한줄 소개]
- 배경: [시대/세계관 간단 설명]
- 분량: [에피소드 목표 분량]
- 총 화수: [목표 화수]

## 주인공

- 이름: [이름]
- 설명: [성격, 외형, 배경 등]

## 핵심 컨셉

[2~3줄로 이 소설의 핵심을 설명]

## 진행

1. 위 정보를 바탕으로 주요 캐릭터 3~5명을 제안해줘 (주인공 포함).
2. 아크 구성과 핵심 약속 3가지를 제안해줘.
3. 내가 OK하면 claude-novel-templates/의 SETUP-GUIDE.md 절차대로 전체 파일을 생성해줘.
   - CLAUDE.md {{PLACEHOLDER}} 전부 채우기
   - settings/ 파일 전부 실제 내용으로 작성
   - plot/ 초기 설계
   - batch-supervisor.md 생성
   - config.json 등록
4. 파일 생성 후, 에이전트 3팀으로 교차 검증 수행 (SETUP-GUIDE.md Step 10 참조).
   모순 발견 시 즉시 수정.
5. 검증 통과 후 git commit (2단계):
   - 소설 폴더: git init + 전체 커밋 (독립 레포)
   - 상위 레포: config.json + vercel.json + .gitignore만 커밋
6. **에피소드 집필은 하지 않는다. 셋업 + 검증까지만.**
```

---

## 프롬프트 3: 풀 자동 (최소 개입)

장르만 던지면 Claude가 알아서 전부 결정한다. 빠르게 테스트하고 싶을 때.

```
claude-novel-templates/ 를 참고해서 새 [장르] 소설을 처음부터 끝까지 자동으로 셋업해줘.

조건:
- 장르: [장르]
- 톤: [자유 / 또는 지정]
- 총 화수: [목표 화수]
- 에피소드 분량: [목표 분량 또는 "기본값"]

나한테 물어보지 말고 네가 판단해서 전부 결정해.
제목, 캐릭터, 세계관, 아크 구성, 모든 설정 파일까지 한번에 만들어줘.
SETUP-GUIDE.md 절차 전체를 수행하고, 교차 검증(Step 10)도 수행해.
모순 발견 시 즉시 수정.
검증 통과 후 git commit 2단계 (소설 폴더 독립 레포 + 상위 레포 등록).
에피소드 집필은 하지 마. 셋업 + 검증만.

다 끝나면 "어떤 소설을 만들었는지" + "검증 결과 요약"을 보여줘.
```

---

## 프롬프트 4: 기존 소설 복제 (실험용)

같은 설정으로 다른 AI가 쓰게 하고 싶을 때. 모델 비교 테스트용.

```
no-title-[원본 번호]/ 소설의 설정을 복제해서 새 프로젝트를 만들어줘.

## 복제 대상
- 원본: no-title-[번호]
- 복제할 것: CLAUDE.md, settings/, .claude/agents/, plot/master-outline.md, plot/foreshadowing.md
- 복제하지 않을 것: chapters/ (빈 폴더만), summaries/ (빈 템플릿만), EDITOR_FEEDBACK*

## 변경 사항
- 새 폴더명: no-title-[새 번호] (자동 결정)
- CLAUDE.md 폴더 구조의 경로를 새 폴더명으로 업데이트
- author를 "[작성자명]"으로 변경 (실험작 태그 트리거용이면 "다슬기")
- batch-supervisor.md 생성 (WRITER_CMD: [집필 모델 명령])
  예시: "claude", "claude --model claude-sonnet-4-6", "claude --model gpt-oss:120b"

## 완료 후
- 교차 검증 (SETUP-GUIDE.md Step 10) — 복제 과정에서 경로/참조가 깨지지 않았는지 확인
- git commit 2단계:
  - 소설 폴더: git init + 전체 커밋 (독립 레포)
  - 상위 레포: config.json + vercel.json + .gitignore만 커밋
- 최종 상태 요약
- **에피소드 집필은 하지 않는다. 셋업까지만.**
```

---

## 셋업 후 집필 시작

프로젝트 생성이 완료되면, 집필은 두 가지 방법으로 시작할 수 있다:

### 방법 A: 직접 집필

```bash
cd /root/novel/no-title-XXX && claude
# → "1화 작성해줘"
```

### 방법 B: 감독자로 배치 집필

```bash
# 상위 폴더에서 감독자 실행
cd /root/novel && claude
# → "no-title-XXX/batch-supervisor.md 대로 수행"
```

감독자가 tmux 세션을 열고 집필 AI를 자동으로 관리한다.
`WRITER_CMD` 변수로 집필 모델을 지정할 수 있다 (기본값: `claude`).

---

## 참고

- 시나리오 제안 단계에서 마음에 드는 게 없으면 "다시" 또는 "이런 방향으로" 라고 하면 된다.
- 2단계에서 캐릭터/플롯을 수정 요청할 수 있다. OK할 때까지 3단계로 넘어가지 않는다.
- 모든 프롬프트에서 `[대괄호]` 안의 내용을 실제 값으로 바꿔서 사용한다.
- 셋업 완료 후 settings/ 파일을 직접 수정해도 된다. CLAUDE.md가 최우선이고 settings/는 세부 규칙이다.
- 4단계 교차 검증에서 발견된 모순은 즉시 수정된다. 집필 중 설정 충돌을 사전에 방지하는 핵심 단계다.
