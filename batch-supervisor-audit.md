# 배치 감사 감독 프롬프트

Claude Code가 tmux 세션을 주기적으로 확인하며, 또 다른 AI 인스턴스의 소설 전수 감사를 자동 감독한다.

> **N화 단위 배치가 필요한 이유:**
> Claude Code는 auto-compact가 있으므로 전체 감사를 한 번에 실행할 수 있다 (`N=-1`).
> 하지만 GLM-5, Qwen 등 auto-compact가 없는 모델은 N화 단위로 감사 → `/clear` → 재개를 반복해야 컨텍스트 초과를 방지할 수 있다.

## 실행 구조

```
/root/novel/                    ← 감독자 Claude Code 실행 위치
├── no-title-XXX/               ← 감사자가 작업하는 소설 폴더
│   ├── batch-supervisor-audit.md  ← 이 파일 (감독 규칙)
│   └── ...
```

- **감독자**: `/root/novel/`(상위 폴더)에서 Claude Code를 열고 이 프롬프트를 입력한다.
- **감사자**: tmux 세션 안에서 소설 폴더로 이동한 뒤 AI를 실행한다.

---

## 설정 변수

아래 값을 소설에 맞게 변경한 뒤 프롬프트를 입력한다.

| 변수 | 설명 | 예시 |
|------|------|------|
| `NOVEL_ID` | 소설 폴더명 | `no-title-001` |
| `SESSION` | tmux 세션명 | `audit-001` |
| `NOVEL_DIR` | 소설 절대 경로 | `/root/novel/no-title-001` |
| `BATCH_SIZE` | 배치당 감사 화수 (N) | `10` |
| `AUDITOR_CMD` | 감사자 실행 명령 | `claude` (기본) |
| `START_EP` | 시작 화수 (선택, 기본 1) | `1` |
| `END_EP` | 종료 화수 (선택, 기본 마지막 화) | `100` |

### BATCH_SIZE 설정 가이드

| 값 | 의미 | 적합한 모델 |
|----|------|-------------|
| `-1` | 전체를 한 번에 감사 (auto-compact 사용) | Claude Code |
| `10` | 10화씩 끊어서 감사 + /clear 반복 | GLM-5, Qwen 등 (컨텍스트 128K) |
| `5` | 5화씩 (보수적) | 컨텍스트가 작은 모델, 에피소드 분량이 큰 소설 |
| `20` | 20화씩 (공격적) | 컨텍스트가 넉넉한 모델 |

### AUDITOR_CMD 예시

| 값 | 설명 |
|----|------|
| `claude` | 기본 Claude Code |
| `claude --model claude-sonnet-4-6` | 특정 모델 지정 |
| `claude --model glm-5:latest` | NIM 프록시 경유 GLM-5 |

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

{{NOVEL_ID}} 소설의 배치 감사를 감독해줘. 아래 규칙대로 진행해.

### 1. 세션 관리

- tmux 세션명: `{{SESSION}}`
- **세션이 없으면**: `tmux new-session -d -s {{SESSION}} -x 220 -y 50` 으로 생성하고, `tmux send-keys -t {{SESSION}} 'cd {{NOVEL_DIR}} && unset CLAUDECODE && {{AUDITOR_CMD}}' Enter` 실행
- **세션이 있으면**: 화면을 캡처하여 현재 상태를 파악하고 이어서 진행
- **세션 크기**: 220x50 이상으로 설정해야 capture-pane에서 잘리지 않는다

### 2. 배치 계획 수립

#### BATCH_SIZE = -1 (전체 감사)

1. 감사자에게 `/audit` 또는 `/audit {{START_EP}}-{{END_EP}}` 프롬프트를 전송한다.
2. 완료될 때까지 감독만 수행한다. `/clear`는 하지 않는다 (auto-compact에 맡긴다).

#### BATCH_SIZE = N (N화 단위 배치)

시작~종료 범위를 N화 단위로 분할한다:

```
예: START_EP=1, END_EP=35, BATCH_SIZE=10
→ 배치 1: 1-10
→ 배치 2: 11-20 (--resume 20)
→ 배치 3: 21-30 (--resume 30)
→ 배치 4: 31-35 (--resume 35)
```

- 첫 배치: `/audit {{START_EP}}-{첫 배치 끝}`
- 이후 배치: `/audit --resume {배치 끝}` (tracker 기반 재개)
- 마지막 배치: 남은 화수가 N 미만이면 그대로 진행

### 3. 감사 프롬프트

#### 3a. 첫 배치 프롬프트

```
/audit {{START_EP}}-{BATCH_END}
```

#### 3b. 후속 배치 프롬프트 (/clear 후)

```
/audit --resume {BATCH_END}
```

#### 3c. 전체 감사 프롬프트 (BATCH_SIZE = -1)

```
/audit
```

또는 범위 지정 시:

```
/audit {{START_EP}}-{{END_EP}}
```

### 4. 감독 루프

#### 4a. 화면 캡처

```bash
tmux capture-pane -t {{SESSION}} -p -S -50
```

- `-S -50`: 최근 50줄만 캡처 (토큰 절약)

#### 4b. 상태 판단 기준

| 상태 | 판단 패턴 | 조치 |
|------|-----------|------|
| **작업 중** | `> ` 프롬프트가 없고, 텍스트가 출력되고 있음. 또는 `Working`, `Thinking`, `Simmering` 등 진행 표시 | 2분 후 재확인 |
| **자동 압축 발생** | `Auto-compact` 또는 `Compacting conversation` 메시지 | 정상 동작 (BATCH_SIZE=-1에서 예상됨). 2분 후 재확인 |
| **질문하며 멈춤** | `?`로 끝나는 줄 뒤에 `> ` 프롬프트가 나타남 | 적절한 답변 전송 |
| **권한 요청** | `Allow`, `Deny`, `permission` 등과 함께 입력 대기 | `tmux send-keys -t {{SESSION}} 'y' Enter` |
| **에러 발생** | `Error`, `error`, `FATAL`, `Traceback` 등 | 에러 원인 분석 후 복구 명령 전송 |
| **MCP 연결 실패** | `MCP`, `connection`, `timeout`, `ECONNREFUSED` 등 | `/mcp` 명령으로 재연결 시도. 반복 실패 시 세션 재시작 |
| **무한 루프** | 동일 작업이 3회 이상 반복되거나, 15분 이상 같은 화에서 진전 없음 | `/clear` 후 `--resume` 프롬프트로 재시작 |
| **완료** | `> ` 프롬프트가 나타나고, 직전 출력에 보고서 작성 완료 관련 메시지가 있음 | 다음 배치 진행 또는 전체 완료 |
| **비정상 종료** | AI 프로세스가 없고 bash 프롬프트(`$`)만 보임 | `unset CLAUDECODE && {{AUDITOR_CMD}}`로 재시작 |
| **컨텍스트 초과** | `context`, `token limit`, `too long` 등의 메시지 | `/clear` 후 `--resume` 프롬프트로 재시작. BATCH_SIZE가 너무 큰 것이므로 이후 배치에서 줄인다 |

#### 4c. 완료 판단

배치 완료를 판단하기 위해 아래를 복합 확인한다:

1. **프롬프트 대기**: 화면 마지막 줄에 `> ` 또는 `❯` 프롬프트가 있음
2. **보고서 갱신**: `summaries/full-audit-report.md`가 존재하고, 해당 배치의 마지막 화가 포함됨
3. **tracker 갱신**: `summaries/full-audit-tracker.md`에 해당 배치의 마지막 화가 기록됨

```bash
# 보고서에서 마지막 감사 화수 확인
grep -oP '### \K\d+(?=화)' {{NOVEL_DIR}}/summaries/full-audit-report.md | tail -1

# tracker에서 마지막 완료 화수 확인
grep -oP '마지막 완료.*?(\d+)화' {{NOVEL_DIR}}/summaries/full-audit-tracker.md
```

#### 4d. 배치 전환 절차 (BATCH_SIZE > 0)

한 배치가 완료되면:

1. **보고서 확인**: tracker의 마지막 완료 화수가 배치 끝과 일치하는지 확인
2. **`/clear` 전송**: `tmux send-keys -t {{SESSION}} '/clear' Enter`
3. **3초 대기**: `sleep 3`
4. **다음 배치 프롬프트 전송**: `/audit --resume {다음 배치 끝}`
5. 마지막 배치까지 반복

#### 4e. 감독 주기

| 상황 | 확인 간격 |
|------|-----------|
| 프롬프트 전송 직후 | 30초 후 시작 확인 |
| 작업 진행 중 | 2분 간격 |
| 에러 복구 후 | 1분 간격으로 3회, 이후 정상 간격 |
| `/clear` 후 | 10초 후 확인, 프롬프트 전송 |

### 5. 특수 상황 처리

#### 5a. 컨텍스트 초과 대응

auto-compact가 없는 모델에서 배치 도중 컨텍스트 초과가 발생하면:

1. 현재 배치가 중단된 것이므로 `/clear` 실행
2. tracker에서 실제 마지막 완료 화수를 확인
3. 다음 배치를 기존 BATCH_SIZE보다 **2화 줄여서** 재시도
4. 그래도 실패하면 추가로 줄인다 (최소 3화)
5. 감독자 로그에 조정된 배치 크기를 기록

#### 5b. 보고서 무결성 확인

전체 감사 완료 후:

1. `full-audit-report.md`에 START_EP~END_EP 범위의 모든 화가 포함되는지 확인
2. 누락된 화가 있으면 해당 범위만 추가 감사: `/audit {누락 범위}`
3. 보고서 상단의 **요약 테이블**이 전체 범위를 반영하는지 확인
   - 배치별 재개로 인해 요약이 마지막 배치만 반영할 수 있다
   - 이 경우 감사자에게 요약 재계산을 요청:
     ```
     summaries/full-audit-report.md의 상단 요약 테이블과 전체 패턴 분석을 전 범위({{START_EP}}~{{END_EP}}화)로 재계산해줘. 본문 내용은 수정하지 말고 요약 통계만 갱신.
     ```

#### 5c. 세션 크래시 복구

세션이 완전히 사라진 경우:

1. `tmux ls`로 세션 존재 확인
2. 없으면 세션 재생성 (1번 세션 관리 절차)
3. tracker에서 마지막 완료 화수 확인
4. 다음 배치부터 `--resume` 프롬프트로 재개

### 6. 로그 관리

감독자는 화면에 아래 형식으로 진행 상황을 출력한다:

```
[HH:MM] 배치 감사 시작: {{NOVEL_ID}} {{START_EP}}~{{END_EP}}화, BATCH_SIZE={{BATCH_SIZE}}
[HH:MM] 배치 1/N: {S}-{E}화 프롬프트 전송
[HH:MM] 감사 진행 중 (2m)
[HH:MM] 배치 1/N 완료 (보고: ❌{n} ⚠️{n} 💡{n})
[HH:MM] /clear 수행
[HH:MM] 배치 2/N: --resume {E}화 프롬프트 전송
[HH:MM] 에러 감지: {에러 요약} → 복구 시도
[HH:MM] 컨텍스트 초과 → BATCH_SIZE 10→8 조정
[HH:MM] 전체 감사 완료: ❌{n} ⚠️{n} 💡{n}
[HH:MM] 보고서 무결성 확인 완료
```

### 7. 종료 조건

- END_EP화까지 모든 배치가 완료되면 감독 종료
- 보고서 무결성 확인까지 완료한 뒤 최종 요약 출력:
  ```
  ── 배치 감사 완료 ──
  소설: {{NOVEL_ID}}
  범위: {{START_EP}}~{{END_EP}}화
  배치 수: {N}회
  총 항목: ❌ {n}건, ⚠️ {n}건, 💡 {n}건
  보고서: summaries/full-audit-report.md
  ```
- 복구 불가능한 에러가 3회 연속 발생하면 중단하고 사용자에게 보고
- 감독자 자신의 컨텍스트가 부족해지면 현재 진행 상황을 요약하고, 이어서 감독할 수 있는 프롬프트를 출력한 뒤 종료

### 8. 범위

{{START_EP}}화부터 {{END_EP}}화까지, BATCH_SIZE={{BATCH_SIZE}}.

---

## 감독자 자기 교체 프롬프트

감독자의 컨텍스트가 부족해질 때 아래 형식으로 이어받기 프롬프트를 출력한다:

```
배치 감사 감독을 이어서 해줘.
- 소설: {{NOVEL_ID}}
- 세션: {{SESSION}}
- 전체 범위: {{START_EP}}~{{END_EP}}화
- BATCH_SIZE: {{BATCH_SIZE}}
- 현재 배치: {K}/{N} ({S}-{E}화, {상태})
- 마지막 완료: {M}화
- 남은 범위: {M+1}~{{END_EP}}화
- 특이사항: {있으면 기술}
- batch-supervisor-audit.md의 규칙대로 진행해.
```
