소설 전수 감사를 실행한다.

## 사용법

`/audit` 또는 `/audit no-title-001` 또는 `/audit 1-30` 또는 `/audit --resume`

- 인자 없음: 현재 작업 디렉토리의 소설을 **전 범위** 감사
- 소설 ID: 해당 소설을 전 범위 감사 (예: `/audit no-title-001`)
- 범위(N-M): 해당 화수 범위만 감사 (예: `/audit 1-30`, `/audit 50-80`)
- `--resume`: 이전에 중단된 감사를 tracker 기반으로 재개
- 조합 가능: `/audit no-title-001 1-30`, `/audit --resume`

## 실행

1. 대상 소설 폴더의 `.claude/agents/full-audit.md`를 읽고 지시에 따른다.
2. 본문을 **절대 수정하지 않는다**. 검토 + 보고서 작성만 수행한다.
3. 산출물: `summaries/full-audit-report.md` + `summaries/full-audit-tracker.md`
