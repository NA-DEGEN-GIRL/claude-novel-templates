감사 보고서를 읽고 발견된 오류/경고를 본문에 반영한다.

## 사용법

`/audit-fix` 또는 `/audit-fix 15` 또는 `/audit-fix 10-20` 또는 `/audit-fix --resume`

- 인자 없음: 보고서의 전체 에피소드를 순차 수정
- 숫자 1개: 해당 화만 수정
- 범위(N-M): N화부터 M화까지 수정
- `--resume`: 이전에 중단된 수정을 tracker 기반으로 재개

## 실행

1. 대상 소설 폴더의 `.claude/agents/audit-fixer.md`를 읽고 지시에 따른다.
2. `summaries/full-audit-report.md`가 없으면 `/audit`을 먼저 실행하라고 안내한다.
3. 산출물: 수정된 본문 + 요약 파일 갱신 + `summaries/full-audit-tracker.md` 수정 이력 추가
