# 표지 이미지 & 에피소드 삽화

> 표지 이미지는 모든 소설에 적용된다. 에피소드 삽화는 `illustration: true` 시에만 적용된다.

---

## 1. 표지 이미지

소설 루트에 `cover.png`(또는 `.jpg`)를 저장한다.

**자동 생성**: NovelAI MCP 서버의 `generate_image` tool로 생성한다.
- 첫 에피소드 집필 시 `cover.png`가 없으면 자동 생성
- 이미 존재하면 건드리지 않는다 (사용자가 명시적으로 요청할 때만 재생성)

**프롬프트 작성 요소:**
- 주인공의 외형 (`settings/03-characters.md`의 외모 설정)
- 소설의 장르와 분위기 (무협→동양풍, 현대→도시/네온, SF→미래적)
- 핵심 상징물 (검, 마법, 기술 장치 등)
- 톤앤무드 (다크→어두운 조명, 밝음→선명한 색감)
- 표지에 적합한 구도: 상반신 또는 전신, 임팩트 있는 포즈
- 권장 해상도: 832x1216 (세로형)

생성 후:
1. **사용한 프롬프트를 `cover-prompt.txt`에 저장한다** (재생성/수정 시 기준점).

**`cover-prompt.txt` 형식:**

```
[Prompt]
masterpiece, best quality, amazing quality,
1boy, solo, upper body, ...태그...

[Negative Prompt]
lowres, bad anatomy, ...

[Settings]
resolution: 832x1216
tool: generate_cover / generate_image
date: YYYY-MM-DD
```

- 표지를 재생성할 때는 이 파일의 프롬프트를 기반으로 수정한다.
- 프롬프트 없이 표지가 존재하면, 역으로 프롬프트를 추론하여 `cover-prompt.txt`를 작성한다.

### character-prompts.md

소설 루트에 `character-prompts.md` 파일을 생성하여 캐릭터별 이미지 생성 프롬프트를 관리한다.
NovelAI MCP 서버(`novelai-image`)가 이 파일을 파싱하여 자동으로 이미지를 생성한다.

> `illustration: false`여도 `character-prompts.md`는 표지 생성(`generate_cover`)에 활용될 수 있으므로 유지한다.

**불변의 특징 (Immutable Traits)**: 각 캐릭터 프롬프트 블록에 `## 불변의 특징` 섹션을 반드시 포함한다. 삽화/초상화 생성 시 이 특징이 **절대 누락되지 않도록** 프롬프트에 포함된다.

```markdown
## 불변의 특징
- {{특징1}} (예: "왼쪽 눈 아래 점", "오른손 검지 흉터", "은색 귀걸이")
- {{특징2}}
```

> 이 특징들은 variant가 바뀌어도 유지되며, `generate_illustration`/`generate_character` 호출 시 `extra_tags`에 자동 추가된다. 웹툰화 파이프라인 구축 시 캐릭터 시각적 일관성의 핵심 데이터.

**캐릭터 초상화** (`illustration: true` 시): `generate_character` tool로 생성한 이미지는 `assets/characters/`에 저장된다. 캐릭터의 기준 외형을 확인하는 참고 자료로 사용한다.

**초상화 관리 규칙** (`illustration: true` 시):
- 캐릭터 첫 등장 전에 `generate_character`로 기본 초상화를 생성해 둔다
- 외모가 크게 변하는 경우 (변신, 시간 경과, 변장 등) 해당 변형의 초상화도 생성한다
- 변형 초상화 파일명: `{캐릭터명}-{변형명}.png` (예: `사쿠라-방송_모드.png`)

---

## 2. 에피소드 삽화

> **이 섹션은 `illustration: true` 시에만 적용된다.** `illustration: false`(기본)이면 에피소드 삽화 생성을 건너뛴다. 사용자가 명시적으로 삽화를 요청하면 이 섹션의 규칙을 따른다.

### 삽입 기준

매 에피소드가 아닌, **아래 상황에서만** 삽화를 삽입한다:

- 캐릭터 첫 등장 또는 외모 변화 (변장, 부상, 새 의상 등)
- 감정적으로 인상적인 장면 (결투 직후, 고백, 이별 등)
- 새로운 장소/세계관 요소가 처음 등장할 때
- 에피소드 전체 톤을 시각적으로 강조하고 싶을 때

> 매 화 넣지 않는다. 정말 시각적으로 강한 장면일 때만 넣어야 효과가 있다. 빈도는 자유롭게 판단하되, 남발하지 않는다.

### 삽화 생성 방법

**반드시 `generate_illustration` tool을 사용한다** (캐릭터 일관성 자동 보장):

```
generate_illustration(
  novel_id="{{NOVEL_ID}}",
  scene_prompt="장면/배경/분위기 태그 (캐릭터 외모 태그는 넣지 않는다)",
  characters=[
    {"name": "캐릭터A"},
    {"name": "캐릭터B", "variant": "변형명", "extra_tags": "장면 전용 추가 태그"}
  ],
  output_filename="chXXX-scene-name.png"
)
```

**동작 원리:**
1. `character-prompts.md`에서 캐릭터 태그를 자동 로드하여 V4 char_captions로 전달
2. 캐릭터별 좌표 지정으로 다인물 구도에서 정확한 배치
3. 장면/배경 태그와 캐릭터 외모 태그가 분리되어 속성 혼동 방지

> **`generate_image`는 에피소드 삽화에 사용하지 않는다.**
> `generate_image`는 캐릭터 태그를 자동 로드하지 않으므로 캐릭터 외모가 일관되지 않는다.

### 삽화 형식 (필수 — 이 형식만 허용)

에피소드 본문 끝(EPISODE_META 직전)에 **반드시 아래 blockquote 형식으로** 삽입한다:

```markdown
---

> **삽화**: {{캐릭터명}} — {{상황 설명}}
> ![삽화]({{이미지 경로}})
```

> **필수**: 반드시 `>` blockquote + `**삽화**:` 설명 라인을 포함해야 한다.
> 리더가 이 형식을 파싱하여 삽화 설명을 표시한다.
> `![설명](path)` 만 단독으로 쓰는 것은 **금지** — 설명이 표시되지 않는다.

- 이미지 경로는 `{{NOVEL_ID}}/assets/illustrations/` 하위.
- `character-prompts.md`에 해당 캐릭터의 프롬프트가 없으면 먼저 추가한다.
- 삽화가 포함된 에피소드는 `summaries/illustration-log.md`에 기록하여 추적한다

### 삽화 추적 (필수)

삽화를 생성할 때마다 `summaries/illustration-log.md`에 기록한다:
- 에피소드 번호, 파일명, 등장 캐릭터, scene_prompt, 생성일
- 이 기록이 없으면 재생성/감사 시 일관성 유지가 불가능하다

### 삽화 관리

`.claude/agents/illustration-manager.md`로 삽화를 체계적으로 관리한다:
- **단건 검증**: 삽화 삽입 직후 이미지-본문 일치, 태그 정합성, 형식 등 6항목 검증
- **일괄 감사**: 아크 종료 시 전체 삽화 점검 (외모 변화 반영, 고아 이미지, 깨진 참조 등 11항목)
- **재생성**: 감사에서 문제 발견 시, 기존 프롬프트 기록 기반으로 수정 후 재생성

---
