---
title: "[트러블슈팅] 상황별 대처 가이드 — 막혔을 때 무엇부터 나눠 볼까"
date: 2026-10-27 10:00:00 +0900
categories: [m365, troubleshooting]
tags: [트러블슈팅, 가이드, 목록]
excerpt: "막혔던 상황을 작업 영역별로 모은 목록. 상황마다 글이 따로 있고, 이 글은 어떤 순서로 나눠 볼지와 글 목록만 정리"
---

> 이 글은 목록입니다. 각 상황은 별도 글에 증상, 먼저 확인할 것, 시도와 결과, 운영 판단, 근거를 적었습니다.

## 막혔을 때 나눠 보는 순서

1. **화면(GUI)에서는 되는데 Graph·REST에서만 안 되는가** → 사람의 권한이 아니라 토큰의 범위 문제일 가능성이 큽니다.
2. **화면에서도 안 되는가** → 역할 부족(예: Azure 루트 범위)이거나 반영 시간을 더 기다려야 하는 경우입니다.
3. **로그인 단계에서 막히는가** → 오류 코드부터 읽고, 보안 설정을 바꾸기 전에 바꾸지 않는 선택지를 먼저 비교합니다.
4. **화면도 Graph도 비어 있거나 서버 오류로 거부되는가** → 403(권한)과 404(데이터·등록 상태)를 나누고, 시각을 달리해 다시 확인합니다.
5. **스크립트로 여러 개를 읽을 때 막히는가** → 전부 같은 모양이면 연결·토큰, 항목별이면 범위·모듈·값 형태를 봅니다.

공통 원칙은 세 가지입니다.

- 막히면 설정·역할을 바꿔서 뚫기 전에 원인을 좁히는 **읽기 전용 확인**부터 합니다.
- 안 된 것은 "안 됨"으로 끝내지 않고 **시도한 방법과 막힌 이유**를 함께 남깁니다.
- 임시로 켠 권한(Elevate, 동의한 범위)은 쓴 뒤 **끄거나 철회**하고, 끈 것을 다시 확인합니다.

## 영역별 글 목록

### 로그인·권한

| 상황 | 한 줄 요약 |
|---|---|
| [Exchange Online 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}) | Connect-ExchangeOnline -Device가 막힌 증상을 오류 코드 표와 로그인 로그로 보안 기본값 차단이라고 확정하고, 설정을 바꾸지 않고 선택할 수 있는 해결 경로까지 정리한 기록 |
| [관리 그룹 설정이 403 — Elevate access를 켜도 값이 안 읽힐 때 (토큰과 REST)]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}) | HTTP 403으로 못 읽은 관리 그룹 설정을 Elevate access를 켜고 읽은 과정, 포털 화면과 REST의 결과가 다른 점, 토큰 갱신 가설이 증거 부족임을 정리한 기록 |
| [Elevate access를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}) | Entra 토글로 Elevate access를 끄려 하자 '권한이 부족하여' 오류가 두 번 나서, 루트 범위 User Access Administrator 할당을 PowerShell로 제거하고 감사 로그로 확인한 기록 |
| [루트 IAM에 경고가 뜨고, Elevate를 끈 뒤 루트 역할 목록이 열리지 않음]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }}) | 켠 상태의 루트 IAM에 뜬 denyAssignments/read 경고의 원인과, 끈 뒤 루트 역할 목록을 직접 읽지 못해 대체 근거로 제거를 확인한 과정 |

### Teams·채널·파일

| 상황 | 한 줄 요약 |
|---|---|
| [비공개·공유 채널 파일이 403 — 멤버십 문제인가, 토큰 범위 문제인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) | 표준 채널은 올라가는데 비공개·공유 채널만 403이어서, 화면·멤버십·토큰 범위 순으로 나눠 확인하고 읽기 범위를 동의해 원인을 좁힌 기록 |
| [채널 경로로 업로드하면 400 "AAD 계정에서는 지원되지 않음"]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }}) | 채널 filesFolder 경로에 바로 PUT 하면 400이 나서, filesFolder의 driveId·itemId를 구해 드라이브 경로로 올린 방법 |
| [채널 업로드 응답은 403인데 파일이 만들어졌을 때]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }}) | 비공개·공유 채널 폴더에 올릴 때 Graph는 403을 돌려줬지만 SharePoint 화면에는 파일이 있었다. 응답 코드만 보지 말고 저장 위치를 같이 확인한다 |
| [공유 채널이 unknownFutureValue로 보일 때]({{ "/m365/troubleshooting/shared-channel-unknownfuturevalue/" | relative_url }}) | Graph allChannels에서 공유 채널의 membershipType이 unknownFutureValue로 나온다. 유형 문자열로 분기하지 말고 filesFolder로 실제 주소를 얻는다 |
| [관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때]({{ "/m365/troubleshooting/channel-count-mismatch/" | relative_url }}) | 관리 센터 열 값은 채널 유형별로 나뉘고 Graph는 General을 포함한 4개를 돌려준다. 활성 사이트에는 채널 사이트가 별도 행이 아니라 링크로 묶여 보인다 |
| [브라우저 파일 선택창을 쓸 수 없을 때]({{ "/m365/troubleshooting/browser-file-picker-unavailable/" | relative_url }}) | 실습 환경에서 브라우저의 파일 선택 대화상자를 쓸 수 없어 Cloud Shell의 Graph 호출로 시험 파일을 올렸다. 직접 업로드와 결과가 같은지는 확인 불가 |
| [개인 달력이 403일 때 — Calendars 범위와 일정 저장 위치]({{ "/m365/troubleshooting/personal-calendar-403-calendars-read/" | relative_url }}) | 같은 토큰으로 팀(그룹) 달력은 읽히는데 개인 달력은 403이다. Calendars.Read를 동의하면 200이 되고, 달력 소유자로 팀 일정과 개인 일정의 저장 위치를 나눌 수 있다 |
| [관리자 OneDrive가 "기본 문서 라이브러리를 찾을 수 없음"으로 열리지 않을 때]({{ "/m365/troubleshooting/onedrive-default-library-not-found/" | relative_url }}) | 오전에는 OneDrive가 오류로 열리지 않고 Graph /me/drive도 403이었다. 오후에 다시 열자 정상이었고 My files에 Meetings·Recordings 폴더가 있었다 |
| [만들어 둔 개인 일정이 사라졌을 때]({{ "/m365/troubleshooting/personal-event-disappeared/" | relative_url }}) | Outlook 웹에서 만들어 둔 개인 시험 일정이 보이지 않았다. 원인은 확인 불가라서 같은 이름·시각으로 GUI에서 다시 만들고 경위를 남겼다 |

### 라이선스·그룹

| 상황 | 한 줄 요약 |
|---|---|
| [가이드가 안내한 메뉴가 화면에 없다]({{ "/m365/troubleshooting/guide-menu-differs-from-portal/" | relative_url }}) | 가이드의 '제품 상세 > 앱 탭'이 화면에 없을 때 사용자 선택 후 '앱 및 서비스 관리'로 실제 경로를 찾은 기록 |
| [원복한 Planner 체크가 다시 해제돼 있다 — 감사 로그로 원인 좁히기]({{ "/m365/troubleshooting/planner-unchecked-license-audit/" | relative_url }}) | 켜서 원복한 Planner가 나중에 다시 꺼져 보였을 때 Entra 감사 로그의 Change user license 기록으로 범위를 좁힌 과정. 원인은 확인 불가 |
| [그룹 라이선스를 Entra에서 할당할 수 없다]({{ "/m365/troubleshooting/license-assignment-not-in-entra/" | relative_url }}) | Entra 그룹의 라이선스 탭에 할당 버튼이 없을 때 M365 관리 센터에서 그룹을 대상으로 할당하는 방법과 필요 역할·제약 |
| [직접 라이선스와 그룹 라이선스가 겹쳤을 때 어떻게 보이는가]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }}) | 이미 직접 E5를 가진 사용자가 같은 E5를 가진 동적 그룹에 들어갈 때의 상태를 읽은 기록. 2건 모두 Active, 원복 후 그룹 할당만 회수, 사용 수 20/25 유지 |
| [동적 그룹 규칙이 얼마 만에 반응하는지 알 수 없다]({{ "/m365/troubleshooting/dynamic-group-reaction-time/" | relative_url }}) | 부서 값을 바꾼 뒤 동적 그룹 구성원이 들어오고 나가기까지의 시간을 20초 간격 폴링과 감사 로그로 잰 기록. 들어올 때 9초, 나갈 때 5분 35초로 편차가 큼 |
| [라이선스 사용 수가 기록(18/25)과 조회(20/25)로 다르다]({{ "/m365/troubleshooting/license-seat-count-mismatch/" | relative_url }}) | 기록상 18/25와 조회값 20/25가 달랐던 이유를 날짜별 사용자 수(17+1+2)로 맞춰 본 기록 |

### Graph·Cloud Shell·스크립트

| 상황 | 한 줄 요약 |
|---|---|
| [Cloud Shell 토큰으로 Graph를 호출하면 되는 것과 403이 나는 것이 갈림]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) | Cloud Shell의 Azure 로그인으로 받은 Graph 토큰으로 읽은 것과 읽지 못한 것을 나누고, 보안 설정을 바꾸지 않고 쓸 수 있는 방법과 막혔을 때의 선택지를 정리한 기록 |
| [Cloud Shell이 다시 시작되어 변수가 사라지거나, 붙여 넣은 명령이 구문 오류가 남]({{ "/m365/troubleshooting/cloud-shell-reset-and-syntax-error/" | relative_url }}) | 다른 주소로 이동하면 Cloud Shell 세션이 초기화되어 변수가 사라지고, 셸이 준비되기 전에 붙여 넣으면 두 번 실행되거나 ParserError가 나는 현상과 대처 |
| [조회 스크립트 결과가 전부 실패로 나옴 — 토큰 만료와 오류 유형 구분]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }}) | 여러 설정을 한 번에 읽는 스크립트가 전 항목 실패했을 때 공통 원인(토큰)부터 보고, 남은 실패 메시지를 유형별로 나눠 처리한 기록 |
| [$top=999를 줬는데 Graph가 100건만 돌려줌 — @odata.nextLink 페이징]({{ "/m365/troubleshooting/graph-paging-100-limit/" | relative_url }}) | 메시지 센터 게시물 목록이 한 번에 100건만 올 때 nextLink를 끝까지 따라가 전체(5페이지)를 읽은 기록 |
| [빈 값(null) 때문에 스크립트 계산이 실패하거나 항목이 누락되고, 결과 표의 이름 열이 섞임]({{ "/m365/troubleshooting/null-values-in-scripts/" | relative_url }}) | 화면에서는 빈 칸이던 값을 스크립트가 계산하다 예외가 나거나 누락되는 경우와, 한 열이 두 개체를 가리켜 표가 헷갈리는 경우를 고친 기록 |
| [같은 설정인데 화면 값과 PowerShell 값이 다르게 읽힘]({{ "/m365/troubleshooting/screen-vs-command-value-mismatch/" | relative_url }}) | 기본 링크 권한이 화면에서는 편집, Get-SPOTenant에서는 None으로 읽힐 때 하나로 단정하지 않고 둘 다 기록한 기록 |
| [문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }}) | Graph 하위 모듈 누락, Cloud Shell 토큰으로 접속되지 않는 서비스 모듈, 서비스별 연결을 모듈 · 연결 · 권한 순서로 나눠 푼 기록 |

### 보고서·감사·청구

| 상황 | 한 줄 요약 |
|---|---|
| [사용 현황 보고서가 '데이터 없음'이고 Graph는 404 UnknownTenantId]({{ "/m365/troubleshooting/usage-report-no-data/" | relative_url }}) | 활동 보고서가 비어 있을 때 권한 오류(403)와 데이터 부재(404)를 나눠 보고, 시각을 달리해 반복 확인한 기록 |
| [감사 로그를 켜는 명령이 InvalidOperationInDehydratedContextException으로 거부됨]({{ "/m365/troubleshooting/audit-log-enable-rejected/" | relative_url }}) | 통합 감사 로그 수집이 꺼져 있고 켜는 명령이 서버 오류로 거부될 때, 권한 부족과 조직 상태 문제를 나눠 보고 어디까지 확인했는지 정리한 기록 |
| [청구 범위와 청구 역할이 보이지 않음 — 청구 범위 목록이 0건]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }}) | Azure 비용 관리 + 청구에서 청구 범위가 0건이라 청구 계정 유형과 청구 역할을 읽지 못했을 때, 어디까지 확인하고 무엇을 하지 않았는지 정리한 기록 |
| [관리 센터 화면이 로딩에서 멈추거나 "프로비전 중" 안내만 나옴]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }}) | M365 Apps 관리 센터가 두 번 로딩에서 멈추고, 다시 열자 앱 인벤토리에 프로비전 안내만 나올 때 값과 도구 문제를 나눠 본 기록 |

작업 순서대로 읽으려면 상단 메뉴의 Category에서 "준비 → 구조 이해 실습 → 운영 설정 실측" 순서로 봅니다.
