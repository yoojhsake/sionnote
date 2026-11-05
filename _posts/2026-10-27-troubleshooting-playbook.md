---
title: "[Troubleshooting] 상황별 대처 가이드: 막혔을 때 무엇부터 나눠 볼까"
date: 2026-10-27 10:00:00 +0900
categories: [m365, troubleshooting]
tags: [Troubleshooting, 가이드, 목록]
excerpt: "막혔을 때 다섯 가지 질문으로 원인 방향을 먼저 나누고, 같은 상황을 다룬 글로 바로 찾아가는 목록입니다."
---

화면에서는 되는데 Graph에서만 403이 나거나, 로그인 단계에서 오류 코드만 보일 때 어디부터 봐야 할까요? 아래 다섯 가지 질문으로 원인 방향을 먼저 나누고, 영역별 목록에서 같은 상황을 다룬 글로 바로 넘어가면 됩니다.

## 막혔을 때 나눠 보는 순서

1. 화면(GUI)에서는 되는데 Graph나 REST에서만 안 되는가. 그렇다면 사람의 권한이 아니라 **토큰의 범위** 문제일 가능성이 큽니다.
2. 화면에서도 안 되는가. 역할 부족(예: Azure 루트 범위)이거나 반영 시간을 더 기다려야 하는 경우입니다.
3. 로그인 단계에서 막히는가. 오류 코드부터 읽고, 보안 설정을 바꾸기 전에 바꾸지 않는 선택지를 먼저 비교합니다.
4. 화면도 Graph도 비어 있거나 서버 오류로 거부되는가. 403(권한)과 404(데이터·등록 상태)를 나누고, 시각을 달리해 다시 확인합니다.
5. 스크립트로 여러 개를 읽을 때 막히는가. 전부 같은 모양이면 연결이나 토큰, 항목별로 다르면 범위, 모듈, 값 형태를 봅니다.

어느 경우든 설정이나 역할을 바꾸기 전에 **읽기 전용 확인**으로 원인을 좁혔고, 안 된 것은 시도한 방법과 막힌 이유를 남겼습니다. 임시로 켠 권한(Elevate, 동의한 범위)은 쓴 뒤 끄거나 철회하고 다시 확인했습니다.

> 이 글은 목록입니다. 각 상황은 별도 글에 요약, 증상, 원인과 해결, 운영 판단, 확인 과정, 근거를 적었습니다.

## 영역별 글 목록

자주 막히는 영역과 먼저 읽을 글을 위에 두었습니다.

### 로그인·권한

- [Exchange Online 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})
    - Connect-ExchangeOnline -Device가 막힌 원인을 오류 코드 표와 로그인 로그로 보안 기본값 차단이라고 확정하고, 설정을 바꾸지 않는 해결 경로를 정리했습니다.
- [관리 그룹 설정이 403: Elevate access를 켜도 값이 안 읽힐 때 (토큰과 REST)]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }})
    - Elevate access를 켜고 읽은 과정, 포털과 REST 결과의 차이, 토큰 갱신 가설이 증거 부족인 점
- [Elevate access를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }})
    - Entra 토글에서 '권한이 부족하여' 오류가 두 번 나서 루트 범위 User Access Administrator 할당을 PowerShell로 제거하고 감사 로그로 확인했습니다.
- [루트 IAM에 경고가 뜨고, Elevate를 끈 뒤 루트 역할 목록이 열리지 않음]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }})
    - 켠 상태의 denyAssignments/read 경고, 끈 뒤 대체 근거로 제거를 확인한 과정

### 로그인·권한: Entra ID(IAM) 대처 가이드

Microsoft Learn 문서 기준입니다.

- [로그인은 되는데 403·AuthorizationFailed가 나올 때]({{ "/iam/troubleshooting/signed-in-but-403/" | relative_url }})
- [AADSTS50126: 사용자 이름 또는 암호가 잘못됨]({{ "/iam/troubleshooting/aadsts50126-wrong-password/" | relative_url }})
- [AADSTS50076·50079: MFA가 필요하거나 등록하라고 막힐 때]({{ "/iam/troubleshooting/aadsts50076-mfa-required/" | relative_url }})
- [AADSTS53003: 조건부 액세스 정책 때문에 차단될 때]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }})
- [조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})
- [계정을 막았는데 퇴사자가 여전히 메일·파일에 접근할 때]({{ "/iam/troubleshooting/disabled-user-still-signed-in/" | relative_url }})
- [보안 기본값 관리가 보이지 않을 때]({{ "/iam/troubleshooting/security-defaults-cannot-enable/" | relative_url }})
- [SMS·음성으로만 MFA를 하는 사용자가 있을 때]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }})
- [셀프 서비스 암호 재설정(SSPR)이 되지 않을 때]({{ "/iam/troubleshooting/sspr-cannot-reset/" | relative_url }})
- [통과 인증(PTA) 환경에서 전원이 로그인하지 못할 때]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }})
- [AADSTS50105: 앱에 할당되지 않은 사용자]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }})
- [AADSTS65001·90094: 앱 권한 동의가 막힐 때]({{ "/iam/troubleshooting/aadsts65001-consent-required/" | relative_url }})
- [AADSTS50020: 게스트가 이 테넌트에 없는 계정으로 막힐 때]({{ "/iam/troubleshooting/aadsts50020-guest-not-in-tenant/" | relative_url }})

### Graph·Cloud Shell·스크립트

- [Cloud Shell 토큰으로 Graph를 호출하면 되는 것과 403이 나는 것이 갈림]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})
    - Cloud Shell의 Azure 로그인 토큰으로 읽은 것과 못 읽은 것, 보안 설정을 바꾸지 않는 방법과 막혔을 때의 선택지
- [조회 스크립트 결과가 전부 실패로 나옴: 토큰 만료와 오류 유형 구분]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }})
    - 공통 원인(토큰)부터 보고, 남은 실패 메시지는 유형별로 나눠 처리합니다.
- [문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }})
    - Graph 하위 모듈 누락, Cloud Shell 토큰으로 접속되지 않는 서비스 모듈, 서비스별 연결 누락을 모듈, 연결, 권한 순으로 풀었습니다.
- [$top=999를 줬는데 Graph가 100건만 돌려줌: @odata.nextLink 페이징]({{ "/m365/troubleshooting/graph-paging-100-limit/" | relative_url }})
    - 메시지 센터 게시물을 nextLink로 끝까지 따라가 전체(5페이지)를 읽었습니다.
- [Cloud Shell이 다시 시작되어 변수가 사라지거나, 붙여 넣은 명령이 구문 오류가 남]({{ "/m365/troubleshooting/cloud-shell-reset-and-syntax-error/" | relative_url }})
    - 다른 주소로 이동하면 세션이 초기화되고, 셸 준비 전에 붙여 넣으면 두 번 실행되거나 ParserError가 나는 현상과 대처
- [빈 값(null) 때문에 스크립트 계산이 실패하거나 항목이 누락되고, 결과 표의 이름 열이 섞임]({{ "/m365/troubleshooting/null-values-in-scripts/" | relative_url }})
    - 화면에서 빈 칸이던 값으로 예외나 누락이 나는 경우, 한 열이 두 개체를 가리키는 경우를 고쳤습니다.
- [같은 설정인데 화면 값과 PowerShell 값이 다르게 읽힘]({{ "/m365/troubleshooting/screen-vs-command-value-mismatch/" | relative_url }})
    - 기본 링크 권한이 화면에서는 편집, Get-SPOTenant에서는 None이라 둘 다 적었습니다.
- [회사 PC에서 모듈이 '정책에 막힘'으로 불러와지지 않을 때: 위치와 PowerShell 버전을 나눠 점검]({{ "/m365/troubleshooting/company-pc-module-blocked/" | relative_url }})
    - Import-Module이 막히는 PC에서 위치와 버전별로 시험해 실행 가능한 조합을 찾았습니다.
- [같은 세션에서 Graph 다음 Exchange 모듈을 불러오면 DLL이 충돌함: 묶음마다 새 세션으로 분리]({{ "/m365/troubleshooting/module-dll-conflict-same-session/" | relative_url }})
    - 한 창에서 이어 실행하면 어셈블리 충돌이 나서 묶음마다 새 pwsh 세션을 열었습니다.
- [이미 접속된 세션을 재사용하는 스크립트가 다른 테넌트를 잴 수 있음: 테넌트 ID로 접속하고 확인한 뒤 실행]({{ "/m365/troubleshooting/script-reuses-existing-session/" | relative_url }})
    - 다른 사람이 만든 스크립트가 기존 접속을 쓰면 엉뚱한 테넌트 값이 섞일 수 있습니다.

### Teams·채널·파일

- [비공개·공유 채널 파일이 403: 멤버십 문제인가, 토큰 범위 문제인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})
    - 표준 채널은 올라가고 비공개·공유 채널만 403이어서 화면, 멤버십, 토큰 범위 순으로 확인하고 읽기 범위를 동의해 좁혔습니다.
- [채널 경로로 업로드하면 400 "AAD 계정에서는 지원되지 않음"]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }})
    - filesFolder의 driveId·itemId를 구해 드라이브 경로로 올린 방법
- [채널 업로드 응답은 403인데 파일이 만들어졌을 때]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})
    - 비공개·공유 채널 폴더 업로드에서 Graph는 403이었지만 SharePoint 화면에는 파일이 있었습니다. 저장 위치를 같이 확인합니다
- [개인 달력이 403일 때: Calendars 범위와 일정 저장 위치]({{ "/m365/troubleshooting/personal-calendar-403-calendars-read/" | relative_url }})
    - 팀(그룹) 달력은 읽히고 개인 달력만 403입니다. Calendars.Read를 동의하면 200이 되고, 달력 소유자로 저장 위치를 나눕니다
- [공유 채널이 unknownFutureValue로 보일 때]({{ "/m365/troubleshooting/shared-channel-unknownfuturevalue/" | relative_url }})
    - Graph allChannels의 membershipType 문자열로 분기하지 말고 filesFolder로 실제 주소를 얻습니다
- [관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때]({{ "/m365/troubleshooting/channel-count-mismatch/" | relative_url }})
    - 관리 센터 열 값은 채널 유형별로 나뉘고 Graph는 General을 포함한 4개를 돌려줍니다. 활성 사이트에는 채널 사이트가 별도 행이 아니라 링크로 묶여 보입니다
- [관리자 OneDrive가 "기본 문서 라이브러리를 찾을 수 없음"으로 열리지 않을 때]({{ "/m365/troubleshooting/onedrive-default-library-not-found/" | relative_url }})
    - 오전에는 Graph /me/drive도 403이었고, 오후에 다시 열자 정상이며 My files에 Meetings, Recordings 폴더가 있었습니다
- [만들어 둔 개인 일정이 사라졌을 때]({{ "/m365/troubleshooting/personal-event-disappeared/" | relative_url }})
    - Outlook 웹의 개인 시험 일정이 보이지 않았습니다. 원인은 확인 불가라서 같은 이름·시각으로 GUI에서 다시 만들고 경위를 남겼습니다
- [브라우저 파일 선택창을 쓸 수 없을 때]({{ "/m365/troubleshooting/browser-file-picker-unavailable/" | relative_url }})
    - Cloud Shell의 Graph 호출로 시험 파일을 올렸습니다. 직접 업로드와 결과가 같은지는 확인 불가

### 라이선스·그룹

- [그룹 라이선스를 Entra에서 할당할 수 없다]({{ "/m365/troubleshooting/license-assignment-not-in-entra/" | relative_url }})
    - 할당 버튼이 없을 때 M365 관리 센터에서 그룹에 할당하는 방법, 필요 역할과 제약
- [직접 라이선스와 그룹 라이선스가 겹쳤을 때 어떻게 보이는가]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})
    - 직접 E5 사용자가 같은 E5 동적 그룹에 들어가면 2건 모두 Active, 원복 후 그룹 할당만 회수, 사용 수 20/25 유지
- [동적 그룹 규칙이 얼마 만에 반응하는지 알 수 없다]({{ "/m365/troubleshooting/dynamic-group-reaction-time/" | relative_url }})
    - 부서 값 변경 후 반영 시간을 20초 간격 폴링과 감사 로그로 쟀습니다. 들어올 때 9초, 나갈 때 5분 35초
- [라이선스 사용 수가 기록(18/25)과 조회(20/25)로 다르다]({{ "/m365/troubleshooting/license-seat-count-mismatch/" | relative_url }})
    - 날짜별 사용자 수(17+1+2)로 차이를 맞춰 봤습니다.
- [가이드가 안내한 메뉴가 화면에 없다]({{ "/m365/troubleshooting/guide-menu-differs-from-portal/" | relative_url }})
    - '제품 상세 > 앱 탭' 대신 사용자 선택 후 '앱 및 서비스 관리'가 실제 경로였습니다.
- [원복한 Planner 체크가 다시 해제돼 있다: 감사 로그로 원인 좁히기]({{ "/m365/troubleshooting/planner-unchecked-license-audit/" | relative_url }})
    - Entra 감사 로그의 Change user license 기록으로 범위를 좁힌 과정. 원인은 확인 불가

### 보고서·감사·청구

- [사용 현황 보고서가 '데이터 없음'이고 Graph는 404 UnknownTenantId]({{ "/m365/troubleshooting/usage-report-no-data/" | relative_url }})
    - 권한 오류(403)와 데이터 부재(404)를 나누고 시각을 달리해 반복 확인했습니다.
- [청구 범위와 청구 역할이 보이지 않음: 청구 범위 목록이 0건]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }})
    - Azure 비용 관리 + 청구에서 청구 계정 유형과 역할을 읽지 못한 범위와, 하지 않은 것
- [관리 센터 화면이 로딩에서 멈추거나 "프로비전 중" 안내만 나옴]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }})
    - M365 Apps 관리 센터가 두 번 멈추고 앱 인벤토리에 프로비전 안내만 나와 값 문제와 도구 문제를 나눠 봤습니다.

### 측정값 해석

- [운영 설정 실측 방법: 읽기 전용 측정과 4단계 판독]({{ "/m365/measurement-method/" | relative_url }})
    - 화면에서 읽은 값을 정상, 주의, 위험, 측정 불가로 나누는 기준과 측정 불가로 남는 사유의 유형

작업 순서대로 읽으려면 상단 메뉴의 Category에서 "준비 → 구조 이해 실습 → 운영 설정 실측" 순서로 봅니다.
