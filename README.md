# Sion's History

주소: https://yoojhsake.github.io/sionnote/ (저장소 이름·주소는 sionnote 그대로, 표시되는 사이트 이름만 바뀜)

Jekyll + Minimal Mistakes(원격 테마). GitHub Pages에서 바로 빌드됩니다.

## 하루 기록 루틴
1. `tools/new-post.ps1 "제목" m365 영문파일이름` (Windows) 또는 `./tools/new-post.sh "제목" m365-readiness`
2. 생성된 `_posts/날짜-영문이름.md`는 **상단 요약 + 구분선 + 하단 풀버전** 구조로 작성. 풀버전은 **목표 → 절차 → 전·후 값 → 문제점·원인·해결 → 검증 → 원복 → 근거 자료** 순서
3. 캡처는 `raw/`에 원본을 두고 `python tools/blur.py raw/파일.png --grid`로 좌표 확인 → `--box`로 가림 → `assets/images/YYYY/MM/`에 저장
4. 올리기 전 체크: 테넌트 ID·구독 ID·이메일·도메인·IP·Request Id·양식 원문이 없는지 확인
5. 커밋 → 푸시(또는 웹에서 업로드) → 1~2분 뒤 사이트 반영

## 카테고리
대분류 m365 / iam / azure / study / blog, 트러블슈팅은 대분류 뒤에 붙이는 하위 분류 (예: `[m365, troubleshooting]`)

## 비공개 자료 분류
외부에 공개하면 안 되는 자료(플랫폼 구조 지도, 업무 양식 등)는 **`_private/` 폴더에만** 둡니다. 이 폴더는 `.gitignore`와 `_config.yml`의 `exclude`에 들어 있어 저장소에도, 사이트에도 올라가지 않습니다. PDF 파일(`*.pdf`)도 `.gitignore`로 막아 두었습니다. 공개 글에는 파일 링크 대신 "비공개 자료(요청 시 별도 공유)"라고만 적습니다.
GitHub 저장소가 공개(public)이면 올라간 파일은 주소를 아는 누구나 받을 수 있고 커밋 기록에도 남으므로, **처음부터 올리지 않는 것**이 유일하게 안전한 방법입니다.

## 숨김 글과 목차
- 글 상단 머리말에 `published: false`를 넣으면 사이트(목록·검색·주소)에서 사라집니다. 저장소 파일은 남으므로 비밀 내용에는 쓰지 않습니다(비밀은 `_private/`).
- 글 제목 앞에는 순서 번호(00, 01, …)를 붙이고, 새 글은 `_pages/readiness.md` 목차 표에 같은 번호로 추가합니다.

## 올리면 안 되는 것
고객사·업무 양식 원문, 계정·테넌트·구독 식별자, 가리지 않은 캡처 (`raw/`는 .gitignore로 제외)
