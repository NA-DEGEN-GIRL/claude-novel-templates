감사 보고서의 크리티컬 항목을 2차 정밀 검증한다.

## 사용법

`/audit-verify` 또는 `/audit-verify 10-20` 또는 `/audit-verify --all` 또는 `/audit-verify --critical`

- 인자 없음: 보고서에서 자동 선별 (연속성 ❌/⚠️ + 부트스트랩 한계 + summaries 불일치)
- 범위(N-M): 해당 화수 범위 내 항목만
- `--all`: ❌/⚠️ 전체 검증 (EPISODE_META 제외, 토큰 많이 소모)
- `--critical`: ❌ 연속성만 검증 (최소 범위)

## 실행

1. 대상 소설 폴더의 `.claude/agents/audit-verifier.md`를 읽고 지시에 따른다.
2. `summaries/full-audit-report.md`가 없으면 `/audit`을 먼저 실행하라고 안내한다.
3. 산출물: `summaries/full-audit-verify.md`

## 권장 운영

- **1차 감사와 다른 모델로 실행**하는 것을 권장한다.
- 이 도구는 **오탐 제거** 도구이지, 미탐 발견 도구가 아니다.
