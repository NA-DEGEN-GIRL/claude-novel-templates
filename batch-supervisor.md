# 배치 집필 감독 프롬프트

Claude Code가 tmux 세션을 주기적으로 확인하며, 또 다른 Claude Code 인스턴스의 소설 집필을 자동 감독한다.

> **왜 스크립트가 아닌 Claude Code인가?**
> bash 스크립트(파일 존재/타임아웃 기반)는 AI의 실제 상태를 판단할 수 없다.
> Claude Code가 직접 tmux 화면을 읽고 맥락을 파악하면 정확한 판단이 가능하다.

## 실행 구조

```
/root/novel/                    ← 감독자 Claude Code 실행 위치
├── no-title-XXX/               ← 집필자가 작업하는 소설 폴더
│   ├── batch-supervisor.md     ← 이 파일 (감독 규칙)
│   └── ...
```

- **감독자**: `/root/novel/`(상위 폴더)에서 Claude Code를 열고 이 프롬프트를 입력한다.
  - 상위 폴더의 CLAUDE.md(프로젝트 가이드)를 읽으므로 config.json 관리 등 전체 맥락을 파악할 수 있다.
- **집필자**: tmux 세션 안에서 소설 폴더(`no-title-XXX/`)로 이동한 뒤 `claude`를 실행한다.
  - 소설 폴더의 CLAUDE.md(집필 헌법)를 읽으므로 해당 소설의 규칙을 정확히 따른다.

---

## 설정 변수

아래 값을 소설에 맞게 변경한 뒤 프롬프트를 입력한다.

| 변수 | 설명 | 예시 |
|------|------|------|
| `NOVEL_ID` | 소설 폴더명 | `no-title-015` |
| `SESSION` | tmux 세션명 | `write-015` |
| `NOVEL_DIR` | 소설 절대 경로 | `/root/novel/no-title-015` |
| `START_EP` | 시작 화수 | `1` |
| `END_EP` | 종료 화수 | `70` |
| `CHUNK_SIZE` | /clear 주기 (화 단위) | `10` |
| `WRITER_CMD` | 집필자 실행 명령 | `claude` (기본) |
| `ARC_MAP` | 아크-화수 매핑 | 아래 참조 |

### WRITER_CMD 예시

| 값 | 설명 |
|----|------|
| `claude` | 기본 Claude Code (소설 폴더의 CLAUDE.md를 자동 로드) |
| `claude --model claude-sonnet-4-6` | 특정 모델 지정 |
| `claude --model gpt-oss:120b` | NIM 프록시 경유 모델 |

### ARC_MAP 예시

```json
{
  "arc-01": [1, 10],
  "arc-02": [11, 20],
  "arc-03": [21, 30]
}
```

---

## 사용법

```bash
# 감독자는 상위 폴더에서 실행
cd /root/novel
claude
```

아래 프롬프트를 Claude Code에 입력:

---

## 프롬프트

{{NOVEL_ID}} 소설의 배치 집필을 감독해줘. 아래 규칙대로 진행해.

### 1. 세션 관리

- tmux 세션명: `{{SESSION}}`
- **세션이 없으면**: `tmux new-session -d -s {{SESSION}} -x 220 -y 50` 으로 생성하고, `tmux send-keys -t {{SESSION}} 'cd {{NOVEL_DIR}} && unset CLAUDECODE && {{WRITER_CMD}}' Enter` 실행
- **세션이 있으면**: 화면을 캡처하여 현재 상태를 파악하고 이어서 진행
- **세션 크기**: 220x50 이상으로 설정해야 capture-pane에서 잘리지 않는다

### 2. 화수-아크 매핑

```
{{ARC_MAP을 여기에 기술}}
```

화수 N이 주어지면 이 매핑에서 해당 아크와 zero-padded 파일명을 결정한다:
- 아크: N이 포함된 범위의 키
- 파일: `chapters/{arc}/chapter-{NN}.md` (NN = zero-padded 2자리 또는 3자리, 100화 이상이면 3자리)

### 3. 집필 프롬프트

#### 3a. 청크 시작 프롬프트 (첫 화 또는 CHUNK_SIZE마다 /clear 후)

```
{N}화를 집필해줘.
[지침]
- .claude/agents/writer.md의 자율 집필 마스터 체크리스트(A~G)를 빠짐없이 수행한다.
- 플롯: plot/{arc}.md 참조
- 집필 전 summaries/running-context.md를 다시 읽어 현재 상태를 확인한다.
- 파일명: chapters/{arc}/chapter-{NN}.md
[리뷰]
1. reviewer, continuity-checker 에이전트 실행
2. mcp__novel_editor__review_episode(episode_file="{{NOVEL_DIR}}/chapters/{arc}/chapter-{NN}.md", novel_dir="{{NOVEL_DIR}}", sources="auto") 호출
3. gemini-feedback 에이전트 포함 외부 AI 편집 리뷰 수행
4. 리뷰 반영 후 korean-proofreader로 한글 교정
[후처리]
- 요약 파일 갱신 (writer.md D단계)
- config.json 업데이트 (에피소드 등록 + totalEpisodes). git add/commit 대상에 포함하지 않는다.
- git commit은 현재 소설 폴더 파일만. push 안 함.
[자율 실행]
- 무인 배치이다. 질문하지 말고 모든 단계를 자율 완료한다.
- 정기 점검 조건 충족 시 바로 수행한다.
```

#### 3b. 청크 내 연속 프롬프트 (이전 화 맥락이 남아 있을 때)

```
이어서 {N}화를 집필해줘. writer.md 체크리스트(A~G) 동일 수행.
- 파일명: chapters/{arc}/chapter-{NN}.md
- 편집 리뷰: mcp__novel_editor__review_episode(episode_file="{{NOVEL_DIR}}/chapters/{arc}/chapter-{NN}.md", novel_dir="{{NOVEL_DIR}}", sources="auto")
- summaries/running-context.md를 다시 읽어 현재 상태를 확인한다.
```

#### 3c. 플롯 생성 프롬프트 (해당 아크의 plot 파일이 없을 때)

```
{arc}의 플롯 파일이 없다. plot/{arc}.md를 먼저 작성해줘.
- plot/master-outline.md와 plot/foreshadowing.md를 참조한다.
- 이전 아크의 plot 파일 형식을 따른다.
- 완료 후 {N}화 집필을 이어서 진행한다.
```

### 4. 감독 루프

#### 4a. 화면 캡처

```bash
tmux capture-pane -t {{SESSION}} -p -S -50
```

- `-S -50`: 최근 50줄만 캡처 (토큰 절약)
- 출력이 길면 상태 판단에 필요한 마지막 부분만 확인

#### 4b. 상태 판단 기준

| 상태 | 판단 패턴 | 조치 |
|------|-----------|------|
| **작업 중** | `> ` 프롬프트가 없고, 텍스트가 출력되고 있음. 또는 마지막 줄이 `Working`, `Thinking`, `Simmering` 등의 진행 표시 | 2분 후 재확인 |
| **자동 압축 발생** | `Auto-compact` 또는 `Compacting conversation` 메시지 | 정상 동작. 2분 후 재확인 |
| **질문하며 멈춤** | `?`로 끝나는 줄 뒤에 `> ` 프롬프트가 나타남. 또는 `(y/n)`, `[Y/n]` 등 입력 대기 | 적절한 답변을 전송: `tmux send-keys -t {{SESSION}} '답변 내용' Enter` |
| **권한 요청** | `Allow`, `Deny`, `permission` 등의 메시지와 함께 입력 대기 | `tmux send-keys -t {{SESSION}} 'y' Enter` |
| **에러 발생** | `Error`, `error`, `FATAL`, `Traceback`, `Permission denied`, `No such file` 등 | 에러 원인 분석 후 복구 명령 전송 |
| **MCP 연결 실패** | `MCP`, `connection`, `timeout`, `ECONNREFUSED` 등 | `/mcp` 명령으로 재연결 시도. 반복 실패 시 세션 재시작 |
| **무한 루프** | 동일 작업이 3회 이상 반복되거나, 10분 이상 같은 화에서 진전 없음 | `/clear` 후 풀 프롬프트로 재시작 |
| **완료** | `> ` 프롬프트가 나타나고, 직전 출력에 집필 완료 관련 메시지 (커밋 완료, batch-progress.log 기록 등)가 있음 | 다음 화 프롬프트 전송 |
| **비정상 종료** | `claude` 프로세스가 없고 bash 프롬프트(`$`)만 보임 | `unset CLAUDECODE && {{WRITER_CMD}}`로 재시작 |

#### 4c. 완료 판단 보강

"완료" 상태를 정확히 판단하기 위해 아래를 복합 확인한다:

1. **프롬프트 대기**: 화면 마지막 줄에 `> ` 또는 `❯` 프롬프트가 있음
2. **작업 산출물 존재**: 해당 화의 chapter 파일이 존재함 (`ls {{NOVEL_DIR}}/chapters/{arc}/chapter-{NN}.md`)
3. **진행 로그 확인**: `tail -1 {{NOVEL_DIR}}/summaries/batch-progress.log`에 해당 화가 기록됨

세 조건 모두 만족해야 "완료"로 판정한다. 프롬프트만 보이고 파일이 없으면 에러로 중단된 것일 수 있다.

#### 4d. 감독 주기

| 상황 | 확인 간격 |
|------|-----------|
| 첫 프롬프트 전송 직후 | 30초 후 시작 확인 |
| 작업 진행 중 | 2분 간격 |
| 에러 복구 후 | 1분 간격으로 3회, 이후 정상 간격 |
| 청크 경계(/clear 후) | 1분 후 시작 확인 |

### 5. 특수 상황 처리

#### 5a. 청크 경계 (/clear)

CHUNK_SIZE(기본 10)화마다 컨텍스트를 초기화한다:

```bash
tmux send-keys -t {{SESSION}} '/clear' Enter
```

3초 대기 후 풀 프롬프트(3a)를 전송한다.

#### 5b. 아크 전환

화수가 새로운 아크 범위에 진입할 때:

1. 이전 아크 마지막 화 완료 확인
2. 새 아크의 `plot/{arc}.md` 존재 확인
   - 없으면 3c 플롯 생성 프롬프트를 먼저 전송
3. 아크 전환 시점은 정기 점검 트리거이므로, 아크 전환 직후 첫 화 프롬프트에 추가:

```
※ 아크 전환 시점이므로 settings/07-periodic.md의 정기 점검(P1~P9)을 먼저 수행한 후 집필을 시작한다.
```

#### 5c. 정기 점검 (5화마다)

5의 배수 화가 완료되면 다음 화 프롬프트에 추가:

```
※ 5화 단위 정기 점검 시점이다. settings/07-periodic.md의 P1~P9를 수행한 후 집필을 시작한다.
```

#### 5d. 세션 크래시 복구

세션이 완전히 사라진 경우:

1. `tmux ls`로 세션 존재 확인
2. 없으면 세션 재생성 (1번 세션 관리 절차)
3. `batch-progress.log`에서 마지막 완료 화수를 확인
4. 다음 화부터 풀 프롬프트로 재개

#### 5e. 이미 완료된 화 건너뛰기

시작 전 `summaries/batch-progress.log`를 읽고 완료된 화를 목록화한다.
이미 완료된 화는 건너뛴다. chapter 파일은 존재하지만 로그에 없는 화는 검증 후 판단한다.

### 6. 로그 관리

감독자는 화면에 아래 형식으로 진행 상황을 출력한다:

```
[HH:MM] {N}화 프롬프트 전송 (청크 시작)
[HH:MM] {N}화 작업 중 (2m)
[HH:MM] {N}화 작업 중 (4m)
[HH:MM] {N}화 완료 확인 → 다음 화 진행
[HH:MM] {N}화 에러 감지: {에러 요약} → 복구 시도
[HH:MM] /clear 수행 (청크 경계)
[HH:MM] 아크 전환: {이전 arc} → {새 arc}
[HH:MM] 정기 점검 지시 (5화 단위)
[HH:MM] 플롯 생성 지시: plot/{arc}.md
```

### 7. 종료 조건

- `END_EP`화까지 모두 완료되면 감독 종료
- 복구 불가능한 에러가 3회 연속 발생하면 중단하고 사용자에게 보고
- 감독자 자신의 컨텍스트가 부족해지면 현재 진행 상황을 요약하고, 이어서 감독할 수 있는 프롬프트를 출력한 뒤 종료

### 8. 범위

{{START_EP}}화부터 {{END_EP}}화까지.

---

## 감독자 자기 교체 프롬프트

감독자의 컨텍스트가 부족해질 때 아래 형식으로 이어받기 프롬프트를 출력한다:

```
배치 감독을 이어서 해줘.
- 소설: {{NOVEL_ID}}
- 세션: {{SESSION}}
- 현재 진행: {N}화 {상태}
- 마지막 완료: {M}화
- 남은 범위: {M+1}~{{END_EP}}화
- 특이사항: {있으면 기술}
- batch-supervisor.md의 규칙대로 진행해.
```
