---
title: "[M365·Azure] 15 트러블슈팅 — 상황별 대처 가이드 (403·로그인 차단·토큰 범위·빈 보고서·스크립트 조회, 요약 + 전체 기록)"
date: 2026-10-27 10:00:00 +0900
categories: [m365, troubleshooting]
tags: [트러블슈팅, "403", 토큰 범위, Graph, Elevate access, AADSTS530035, 동적 그룹, 감사 로그, 페이징, 전체 기록]
excerpt: "이번 주 실습에서 막혔던 상황 16가지를 '증상 → 먼저 볼 것 → 대처 → 확인한 결과' 순서로 모은 가이드. 각 항목은 해당 글로 연결"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell·Graph에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트·구독 ID, 도메인, 계정, 사이트 주소는 게시하지 않았습니다. 이미 올린 글의 결과와 10/26~10/27 재확인 결과를 상황 기준으로 다시 묶고 10/27 확인 결과를 더했습니다.

## 요약

막혔을 때는 **"무엇이 막았는가"를 먼저 나눠 보면** 대처가 빨라집니다. 아래 순서로 나눴습니다.

1. 화면(GUI)에서는 되는데 Graph·REST에서만 안 되는가 → **사람의 권한이 아니라 토큰의 범위** 문제일 가능성이 큽니다.
2. 화면에서도 안 되는가 → **역할·권한 부족**(예: Azure 루트 범위)이거나 **반영 시간**을 더 기다려야 하는 경우입니다.
3. 로그인 단계에서 막히는가 → 오류 코드(예: AADSTS530035)부터 읽고, **보안 설정을 바꾸기 전에** 바꾸지 않는 선택지를 먼저 비교합니다.
4. 화면도 Graph도 **비어 있거나** 켜는 명령이 서버 오류로 거부되는가 → 권한을 올리기 전에 403과 404를 나누고, 시각을 달리해 다시 확인합니다.
5. 스크립트로 여러 개를 읽을 때 막히는가 → 전부 같은 모양이면 연결·토큰, 항목별이면 범위·모듈·값 형태를 봅니다.

| # | 상황(증상) | 먼저 볼 것 | 대처 | 결과 |
|---|---|---|---|---|
| 1 | 관리 그룹 설정 화면이 "권한 없음", REST는 403 | 내가 루트(/) 범위 권한이 있는가 | Elevate access를 켜고 읽은 뒤 **반드시 끔**(GUI 끄기가 실패하면 PowerShell로 루트 할당 제거) | 조회 |
| 2 | 비공개·공유 채널 파일이 Graph에서 403/accessDenied | 같은 계정으로 화면에서 열리는가, 채널 구성원인가 | 구성원·GUI를 확인해 멤버십을 배제하고, 토큰의 Files/Sites 읽기 범위를 추가 | 조회(10/27) |
| 3 | 개인 달력 `/me/calendar`, `/me/events`가 403 | 토큰에 Calendars 범위가 있는가 | Calendars.Read 동의 후 재조회 | 조회(10/27) |
| 4 | 채널 경로로 바로 올리니 400 "AAD 계정에서 지원되지 않음" | 채널 폴더의 driveId·itemId를 구했는가 | `filesFolder`로 두 값을 구한 뒤 `drives/{driveId}/items/{itemId}:/파일:/content`로 업로드 | 조회 |
| 5 | Cloud Shell에서 변수가 사라지거나 구문 오류 | 탭을 옮겼는가, 셸이 준비되기 전에 붙여 넣었는가 | 호출 묶음을 한 번에 붙여 넣고, 준비 표시를 확인한 뒤 입력 | 조회 |
| 6 | `Connect-ExchangeOnline -Device`가 AADSTS530035로 막힘 | 오류 코드 표(보안 기본값 차단) | 설정을 바꾸기 전에 브라우저 대화형 로그인 등 바꾸지 않는 선택지부터 비교 | 조회·문서 |
| 7 | 동적 그룹에 넣었는데 구성원이 바로 안 바뀜 | 변경 시각과 확인 시각의 간격 | "즉시"로 가정하지 말고 몇 분 기다린 뒤, 감사 로그로 정확한 시각 확인 | 조회 |
| 8 | 관리자 OneDrive가 "기본 문서 라이브러리를 찾을 수 없음" | 시간이 지난 뒤에도 같은가 | 오전엔 오류, 오후에 다시 열자 정상. 바로 단정하지 말고 시간을 두고 재시도 | 조회 |
| 9 | 만들어 둔 개인 일정이 사라짐 | 주·월 보기, 검색, 필터 | 원인이 확인되지 않으면 같은 이름·시각으로 GUI에서 다시 만들고 경위를 기록 | 확인 불가 |
| 10 | 사용 현황 보고서가 "데이터 없음", Graph 보고서는 404 `UnknownTenantId` | 403(권한)인가 404(데이터·등록 상태)인가 | 권한을 올리지 않고 활동을 만든 뒤 시각을 달리해 재확인, 48시간 후 재시도 계획 | 확인 불가 |
| 11 | 감사 로그가 꺼져 있고 켜는 명령이 `InvalidOperationInDehydratedContextException`으로 거부 | 안내 문구와 다른 명령의 응답이 모순되는가 | 세션 재연결 포함 4회 시도 후 멈추고 대기·지원 요청·Entra 감사 로그 대체 정리 | 확인 불가 |
| 12 | 스크립트 결과가 **전부 한꺼번에 실패** | 실패가 모두 같은 모양인가 | 토큰 만료로 판단, 다시 연결 후 재실행 | 조회 |
| 13 | `$top=999`를 줬는데 100건만 반환 | 응답에 `@odata.nextLink`가 있는가 | nextLink를 끝까지 따라가 합산 | 조회 |
| 14 | 값이 비어 있을 때 계산에서 예외, 또는 누락 | 대상 값이 null인가 | null 검사 후 "해당 없음" 출력, 대체 시각 사용 | 조회 |
| 15 | 화면 값과 PowerShell 값이 다름 | 같은 속성인지, 표기 차이인지 | 단정하지 않고 둘 다 기록, 다른 속성으로 보완 | 조회·확인 불가 |
| 16 | 명령이 "모듈 없음", 환경에 따라 접속 안 됨 | 모듈·연결·권한 중 어느 쪽인가 | 하위 모듈 명시 또는 REST, 내 PC의 Windows PowerShell 사용 | 조회·문서 |

**공통 원칙 세 가지**

- 막히면 **설정·역할을 바꿔서 뚫기 전에** 원인을 좁히는 읽기 전용 확인부터 합니다.
- 안 된 것은 "안 됨"으로 끝내지 않고 **시도한 방법과 막힌 이유**를 함께 남깁니다.
- 임시로 켠 권한(Elevate, 동의한 범위)은 쓴 뒤 **끄거나 철회**하고, 끈 것을 다시 확인합니다.

---

## 전체 기록

### 1. 관리 그룹 설정이 "권한 없음"·403일 때 (Elevate access)

- **증상**: 포털의 관리 그룹 설정 화면에 읽기 권한이 없다는 안내가 나오고, 같은 설정을 REST로 읽으면 HTTP 403(`AuthorizationFailed`, `managementGroups/settings/read`)이 납니다(조회).
- **원인**: 전역 관리자여도 Azure 루트 관리 그룹의 권한은 자동으로 없습니다(문서: Elevate access).
- **대처**: Entra 관리 센터 > 속성 > "Azure 리소스에 대한 액세스 관리"를 켜서 루트 권한을 얻고, 읽은 뒤 끕니다. 문서는 권한을 올린 뒤 다시 로그인해 액세스를 갱신하라고 안내합니다.
- **알게 된 점**: 포털 설정 화면은 Elevate를 끈 뒤에도 같은 값을 보여 줬지만 REST는 403이었습니다. 이유는 확인 불가라서 "토큰을 갱신해서 읽혔다"고 단정하지 않았습니다.
- **GUI로 끄기가 실패하면**: 같은 토글을 "아니요"로 저장하자 "권한이 부족하여 작업을 완료할 수 없습니다" 오류가 두 번 났고, 원인은 확인 불가입니다. 그때는 루트 범위의 User Access Administrator 할당을 PowerShell로 조회해 제거했습니다.

```powershell
# 루트('/') 범위 User Access Administrator 할당 조회(제거 전에 반드시 내 할당인지 확인)
Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator' |
  Select-Object DisplayName, SignInName, Scope, RoleDefinitionName | Format-List
```

- **주의**: Elevate를 켜 둔 채 방치하지 않습니다. 이번에도 한 번은 약 2시간 30분 켜진 채 있었고, 재개하자마자 읽기 조회만 하고 제거했습니다.
- 자세한 기록: [12 관리 그룹 설정 403]({{ "/m365/troubleshooting/mg-settings-403-elevate-refresh/" | relative_url }})

![Elevate를 끈 상태에서 REST가 403으로 거부된 결과]({{ "/assets/images/2026/10/m12-rest403.png" | relative_url }})
*그림 1. Elevate를 끈 상태에서 관리 그룹 설정을 REST로 읽은 결과(PowerShell). HTTP 403, 코드 AuthorizationFailed. 계정·개체 ID·테넌트 ID는 가렸다.*

### 2. 채널 파일이 Graph에서 403·accessDenied일 때: 멤버십인가, 토큰 범위인가

- **증상**: 비공개·공유 채널에 시험 파일을 올리거나 목록을 읽으면 403이 납니다. 표준 채널은 성공합니다.
- **나눠 보는 순서**
  1. **구성원 확인**: 채널 구성원 목록을 읽어 내 계정이 들어 있는지 봅니다(세 채널 모두 owner 구성원이었음, 조회).
  2. **화면 대조**: 같은 계정으로 SharePoint 화면에서 채널 사이트의 문서 목록이 열리는지 봅니다(두 사이트 모두 열림, 조회).
  3. **토큰 범위 확인**: 토큰의 scp 값만 읽어 Files.*·Sites.*가 있는지 봅니다(없음, 조회).
  4. **읽기 범위 추가 후 재시험**: Graph 탐색기의 "권한 수정" 탭에서 Files.Read.All, Sites.Read.All을 동의하고 같은 요청을 다시 실행합니다.
- **결과(10/27, 조회)**: 동의 전에는 사이트 조회는 200인데 파일 목록은 accessDenied였고, 동의 후에는 두 채널 사이트 모두 파일 목록이 200으로 열렸습니다. 따라서 원인은 멤버십이 아니라 **토큰의 읽기 범위 부족**입니다.
- **확인 불가**: 두 범위를 같이 동의해 한쪽만으로 충분한지는 구분하지 못했습니다. 업로드(쓰기) 성공도 다시 확인하지 않았습니다.
- **정리**: 동의한 읽기 범위는 필요가 없어지면 Entra 관리 센터의 엔터프라이즈 애플리케이션에서 철회합니다.
- 자세한 기록: [13 채널 파일 업로드 403 재현]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }}) §3·§7

![채널별 구성원 확인 결과]({{ "/assets/images/2026/10/m13-4-channel-members.png" | relative_url }})
*그림 2. 세 채널 모두 관리자 계정이 owner 구성원(roles=owner)이다. 계정 부분은 가렸다.*

![동의 후 비공개 채널 사이트 파일 목록 200]({{ "/assets/images/2026/10/m22-2-private-channel-files-200.png" | relative_url }})
*그림 3. 읽기 범위 동의 후 비공개 채널 사이트의 파일 목록 조회가 200 OK. 요청 주소와 식별자는 가렸다.*

### 3. 개인 달력(`/me/calendar`·`/me/events`)이 403일 때

- **증상**: 같은 토큰으로 팀(그룹) 달력은 읽히는데 개인 달력은 403(`ErrorAccessDenied`)입니다.
- **원인과 대처**: 토큰에 Calendars 읽기 범위가 없었습니다. Graph 탐색기에서 Calendars.Read를 동의하고 다시 조회하자 `GET /me/calendar`가 **200 OK**였고 달력 소유자(owner)가 사용자 계정으로 나왔습니다(조회, 10/27). 팀 달력의 소유자는 그룹 계정이었습니다.
- **의미**: **팀 일정은 그룹 사서함, 개인 일정은 사용자 사서함의 달력**에 저장된다는 것을 달력 소유자 기준으로 확인했습니다. 사서함 내부의 물리 저장 위치와 개인 회의가 그 달력에 쌓이는 점은 문서 기준입니다.
- 자세한 기록: [03 D3 Teams 저장 구조]({{ "/m365/readiness-d3-teams-storage/" | relative_url }})

![내 달력 조회 결과, 소유자는 사용자 계정]({{ "/assets/images/2026/10/m22-1-me-calendar-owner-200.png" | relative_url }})
*그림 4. 캘린더 읽기 범위 동의 후 `GET /me/calendar` 응답(200 OK). owner가 사용자 계정이다. 사용자 이름·주소와 식별자는 가렸다.*

### 4. 채널 경로로 업로드하면 400 "AAD 계정에서 지원되지 않음"

- **증상**: `teams/{id}/channels/{id}/filesFolder/content`로 바로 PUT하면 세 채널 모두 HTTP 400이 납니다.
- **대처**: 채널의 파일 폴더 정보(`filesFolder`)에서 `driveId`와 `itemId`를 먼저 읽고, `PUT drives/{driveId}/items/{itemId}:/파일명:/content`로 올립니다. 표준 채널은 이 방법으로 성공했습니다(조회).
- **판단 요령**: 업로드 성공 여부는 응답 코드만 보지 말고 **코드와 실제 저장 위치를 둘 다** 확인합니다. 10/22에는 403인데 파일이 생긴 경우가 있었고 원인은 확인 불가입니다(요청·응답을 저장하지 않았음). 재현할 때는 요청과 응답 전체를 파일로 남깁니다.
- 자세한 기록: [14 Cloud Shell에서 Graph 호출]({{ "/m365/troubleshooting/cloud-shell-graph-scope/" | relative_url }})

![채널 경로로 바로 올렸을 때의 400 오류]({{ "/assets/images/2026/10/m14-1-badrequest.png" | relative_url }})
*그림 5. 채널 경로로 바로 올렸을 때 세 채널 모두 "HTTP 400 - This API is not supported for AAD accounts"가 출력된다. 계정 부분은 가렸다.*

### 5. Cloud Shell이 초기화되거나 구문 오류가 날 때

- **증상**: 다른 주소로 이동하면 세션이 초기화돼 변수가 사라지고, 셸이 준비되기 전에 붙여 넣은 명령은 두 번 실행되거나 구문 오류가 납니다.
- **대처**: 토큰·헤더·주소 변수와 호출을 **한 번에 묶어** 붙여 넣고, 셸이 준비된 것을 확인한 뒤 입력합니다. 구문 오류는 명령 뒤에 다른 글자가 바로 붙을 때 생기는 ParserError였습니다(재현해 확인).
- 자세한 기록: [14 Cloud Shell에서 Graph 호출]({{ "/m365/troubleshooting/cloud-shell-graph-scope/" | relative_url }}) §3

![셸 시작 중 붙여 넣은 명령의 구문 오류]({{ "/assets/images/2026/10/m14-3-parse-error.png" | relative_url }})
*그림 6. 같은 종류의 오류를 재현한 화면. `(Get-Date) clear`를 입력하면 ParserError가 난다. 계정 부분은 가렸다.*

### 6. `Connect-ExchangeOnline -Device`가 AADSTS530035로 막힐 때

- **증상**: 장치 코드 로그인 중 "이에 대한 액세스 권한이 없습니다"와 오류 코드 530035가 나옵니다. 화면에는 앱 이름과 디바이스 상태가 표시됩니다.
- **원인 좁히기**: 오류 코드 표에서 530035는 보안 기본값에 의한 차단(BlockedBySecurityDefaults)이고 화면 문구와 일치했습니다(문서·조회). 같은 오류가 Azure CLI 장치 코드 로그인에서도 났습니다.
- **대처**: **보안 설정을 바꿔서 뚫지 않고**, 설정을 바꾸지 않는 방법(브라우저 대화형 로그인 등)을 먼저 시도하고, 그래도 막히면 보안 기본값 해제처럼 영향이 큰 방법은 변경 이력·원복 계획을 갖춘 뒤에만 쓰는 순서로 정리했습니다.
- 자세한 기록: [05 AADSTS530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})

![장치 코드 로그인 530035 오류]({{ "/assets/images/2026/10/530035-azcli.png" | relative_url }})
*그림 7. az login 장치 코드 로그인이 오류 530035로 막힌 화면. 계정, 요청 ID, 접속 IP는 가렸다.*

### 7. 동적 그룹 구성원이 바로 바뀌지 않을 때

- **증상**: 사용자의 부서 값을 바꿨는데 그룹 구성원 수가 바로 달라지지 않습니다.
- **측정 결과(조회)**: 들어올 때는 두 번 모두 약 20초 안에(2차는 감사 로그 기준 9초) 반영됐고, 나갈 때는 44초 이하에서 **5분 35초**까지 편차가 컸습니다.
- **대처**: 운영에서는 "즉시"라고 가정하지 않고 변경 후 **몇 분 기다린 뒤** 확인합니다. 정확한 시각은 Entra 감사 로그(Update user → Add/Remove member → 그룹 라이선스 변경)로 확인합니다. 기준을 "1분 안쪽"으로 잡으면 부족합니다.
- 한계: 각 방향 2회 측정이고 규모가 작은 테넌트라 큰 환경에서는 다를 수 있습니다.
- 자세한 기록: [02 D2 Identity 구조]({{ "/m365/readiness-d2-identity-groups/" | relative_url }}) 문제 3

![Entra 감사 로그: 부서 변경, 그룹 가입·제거, 라이선스 변경]({{ "/assets/images/2026/10/m02-dyn-audit.png" | relative_url }})
*그림 8. 부서 입력 → 그룹 가입 → 부서 비움 → 그룹 제거 → 그룹 라이선스 회수가 시각순으로 남아 있다.*

### 8. 관리자 OneDrive가 열리지 않을 때

- **증상**: 오전에 OneDrive를 열면 "기본 문서 라이브러리를 찾을 수 없음" 오류가 났고, Graph `/me/drive`도 403이었습니다.
- **대처와 결과**: 오후에 같은 화면을 다시 열자 정상으로 열렸고 My files에 Meetings, Microsoft Copilot Chat Files, Recordings 폴더가 있었습니다(조회). 처음에는 "OneDrive가 없어서"라고 추정했다가 **정정**했습니다.
- **판단 요령**: 403을 "권한 없음"과 "대상이 없음"으로 나눠서 보고, 같은 화면을 시간을 두고 다시 열어 확인합니다. 오류가 사라진 이유는 확인 불가입니다.
- 자세한 기록: [03 D3 Teams 저장 구조]({{ "/m365/readiness-d3-teams-storage/" | relative_url }}) 6-3

### 9. 만들어 둔 개인 일정이 사라졌을 때

- **증상**: 10/28에 넣어 둔 개인 일정이 Outlook 웹에서 보이지 않았고, 검색(`zz-test`)도 0건, 월 보기도 비어 있었습니다.
- **확인한 것**: 주·월 보기와 검색을 해 봤고, 필터는 "예약"만 꺼져 있어 원인이 아니었습니다. 이 일정을 지운 작업은 한 적이 없습니다.
- **대처**: 원인은 **확인 불가**라서 같은 이름·같은 시각으로 GUI에서 다시 만들고(Outlook 웹 → 캘린더 → 새 이벤트 → 저장) 그 경위를 글에 남겼습니다. 사라진 원인을 모르는 채 "원래 있었다"고 쓰지 않았습니다.
- 자세한 기록: [03 D3 Teams 저장 구조]({{ "/m365/readiness-d3-teams-storage/" | relative_url }})

### 10. 사용 현황 보고서가 비어 있을 때 (`UnknownTenantId`)

- **증상**: 관리 센터 사용 현황이 "There is no data for this report."이고, Graph 보고서 호출은 404 `UnknownTenantId`입니다(조회).
- **먼저 볼 것**: 403이면 범위·역할, **404면 데이터·등록 상태**입니다. 보고서 읽기 권한을 따로 동의하지 않았는데도 권한 오류가 아니었습니다.
- **대처**: 권한을 올리지 않고 활동을 만든 뒤 10/26 밤, 10/27 10:29·19:17에 같은 호출을 반복했습니다. 모두 같은 결과였고 원인은 확인 불가입니다. 48시간 이상 지난 뒤 다시 보고, 그래도 같으면 지원 요청합니다.
- 자세한 기록: [16 보고서가 비어 있고 감사 기록이 안 켜질 때]({{ "/m365/troubleshooting/troubleshooting-empty-reports-audit/" | relative_url }}) A

### 11. 감사 로그를 켜는 명령이 거부될 때

- **증상**: `UnifiedAuditLogIngestionEnabled`가 False이고 `Set-AdminAuditLogConfig`가 "먼저 Enable-OrganizationCustomization을 실행하라"는 서버 오류로 거부됩니다. 그런데 그 명령은 "이미 활성화됨"이라고 응답하고 `IsDehydrated`도 False입니다(조회).
- **대처**: 세션을 다시 연결해 4회 시도한 뒤 멈췄습니다. 반복해도 새 정보가 없기 때문입니다. 대기 후 재시도, 계속되면 지원 요청, 그동안은 Entra 감사 로그로 대체합니다. 원인은 확인 불가입니다.
- 자세한 기록: [16 보고서가 비어 있고 감사 기록이 안 켜질 때]({{ "/m365/troubleshooting/troubleshooting-empty-reports-audit/" | relative_url }}) B

![Purview 감사 검색의 기록 시작 버튼과 오류 안내]({{ "/assets/images/2026/10/m23-3-purview-audit-not-recording.png" | relative_url }})
*그림 9. 감사 검색 화면. 상태 확인 오류 안내와 "사용자 및 관리자 활동 기록 시작" 버튼이 표시된다.*

### 12~16. 스크립트·Graph로 한꺼번에 읽을 때

- **12 전부 실패**: 모두 같은 모양으로 실패하면 개별 원인을 찾기 전에 **토큰 만료**부터 확인하고 다시 연결해 재실행합니다.
- **13 100건 제한**: `$top=999`를 줘도 100건씩 오므로 `@odata.nextLink`를 끝까지 따라갑니다(이번에는 5페이지).
- **14 null**: 값이 없을 때 계산하지 않고 "해당 없음"으로 출력하며, 대체할 값(생성 시각 등)을 정합니다.
- **15 화면과 명령 값 차이**: 한쪽으로 단정하지 않고 두 값과 읽은 방법을 모두 적습니다.
- **16 모듈·환경**: 오류가 "인식 안 됨"이면 모듈, "세션 없음"이면 연결, Forbidden이면 권한입니다. Cloud Shell 토큰으로 접속되지 않는 서비스는 내 PC의 PowerShell로 읽었습니다.
- 자세한 기록: [17 여러 설정을 스크립트·Graph로 한꺼번에 읽을 때]({{ "/m365/troubleshooting/troubleshooting-bulk-query/" | relative_url }})

---

## 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access 켜기·끄기 | [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 문서 | 비공개·공유 채널은 별도 사이트 | [Shared channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/shared-channels) |
| 문서 | 파일 업로드·폴더 정보 조회에 필요한 Graph 권한 | [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0), [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0) |
| 조회 | 읽기 범위 동의 전 accessDenied, 동의 후 파일 목록 200 / 내 달력 200 | Graph 탐색기(10/27) |
| 조회 | 구성원·토큰 범위·업로드 결과·동적 그룹 반응 시간 | 해당 글의 근거 표 |
| 조회 | 빈 보고서(UnknownTenantId), 감사 로그 켜기 거부, 스크립트 조회 문제 | [16]({{ "/m365/troubleshooting/troubleshooting-empty-reports-audit/" | relative_url }}), [17]({{ "/m365/troubleshooting/troubleshooting-bulk-query/" | relative_url }}) |
