# SionNote (sionnote.github.io)

Jekyll + Minimal Mistakes(원격 테마). GitHub Pages에서 바로 빌드됩니다.

## 하루 기록 루틴
1. `tools/new-post.ps1 "제목" m365-readiness 영문파일이름` (Windows) 또는 `./tools/new-post.sh "제목" m365-readiness`
2. 생성된 `_posts/날짜-영문이름.md`에 **목표 → 절차 → 실제 값 → 막힌 곳 → 다음** 순서로 작성
3. 캡처는 `raw/`에 원본을 두고 `python tools/blur.py raw/파일.png --grid`로 좌표 확인 → `--box`로 가림 → `assets/images/YYYY/MM/`에 저장
4. 올리기 전 체크: 테넌트 ID·구독 ID·이메일·도메인·IP·Request Id·양식 원문이 없는지 확인
5. 커밋 → 푸시(또는 웹에서 업로드) → 1~2분 뒤 사이트 반영

## 카테고리
m365-readiness / iam / practice / troubleshooting / study / blog

## 올리면 안 되는 것
고객사·업무 양식 원문, 계정·테넌트·구독 식별자, 가리지 않은 캡처 (`raw/`는 .gitignore로 제외)
