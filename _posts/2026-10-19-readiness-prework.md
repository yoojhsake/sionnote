---
title: "[M365·Azure] 00 사전작업 — 환경 점검 전체 기록 (조회 전용)"
date: 2026-10-19 10:00:00 +0900
last_modified_at: 2026-10-23 12:00:00 +0900
categories: [m365]
tags: [M365·Azure, Sandbox, 라이선스, Azure 구독, 환경 점검, 전체 기록]
excerpt: "실습을 시작하기 전에 Sandbox 테넌트와 Azure 구독의 현재 값을 읽기만 해서 남긴 전체 기록. 문서 기준과 실제 값의 차이, 막힌 곳, 근거 자료 포함"
---

조회 기준일은 2026-10-19(월)입니다. 이 날은 **값을 바꾸지 않고 읽기만** 했습니다. 저장·적용·시작 버튼은 한 번도 누르지 않았고, 폼을 열었다면 입력 없이 닫았습니다.

> 이 글은 요약본이 아니라 **전체 기록**입니다. 각 항목마다 (1) 무엇을 확인하려 했는지, (2) 화면(GUI)에서 어떤 경로로 봤는지, (3) PowerShell로 같은 값을 어떻게 맞춰 봤는지, (4) 문서가 말하는 값과 실제 값이 어떻게 다른지, (5) 근거 자료를 순서대로 적었습니다.
> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn 문서 내용 / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유 병기, 2026-10-23 재확인 반영). 테넌트 ID·구독 ID·도메인·계정은 게시하지 않았습니다.

## 1. 이 작업의 목적

실습(10/22)에서 라이선스·그룹·Team·Azure 리소스를 실제로 바꾸기 전에, **바꾸기 전 값**을 남겨 두는 것이 목적입니다. 바꾼 뒤에 "원래대로 돌아왔는가"를 판단하려면 전 값이 있어야 합니다. 그래서 사전작업은 아래 다섯 가지 질문에 값으로 답하는 일이었습니다.

1. 나는 이 테넌트에서 어떤 권한을 갖고 있는가? (관리자 역할)
2. 로그인 보호 장치는 어떤 상태인가? (MFA, 보안 기본값)
3. 어떤 라이선스가 몇 개 있고, 그 안에 어떤 서비스가 들어 있는가? (SKU, 서비스 플랜)
4. Azure 구독은 어떤 종류이고, 돈이 나갈 수 있는 구조인가? (구독 유형, 지출 한도, 할당량)
5. 가이드가 "10/23까지 확인"하라고 한 보완 항목은 지금 어떤 상태인가?

## 2. 먼저 알아야 할 개념 (쉬운 설명)

| 용어 | 쉬운 설명 |
|---|---|
| Tenant(테넌트) | 회사의 계정 묶음, 즉 "신원 경계"입니다. 사용자·그룹·도메인이 여기에 있습니다. |
| Subscription(구독) | Azure에서 요금과 리소스를 묶는 단위입니다. 구독은 정확히 하나의 테넌트를 신뢰하고, 한 테넌트는 구독을 여러 개 가질 수 있습니다. |
| SKU(라이선스 제품) | 판매 단위 한 종류입니다. 이 안에 서비스 플랜(Teams, Entra ID P2 등)이 여러 개 들어 있습니다. |
| 서비스 플랜 | SKU 안의 개별 기능입니다. 사용자별로 켜고 끌 수 있습니다(조직 수준 항목은 제외). |
| 보안 기본값 | 별도 설정 없이 MFA 등 기본 보호를 한꺼번에 켜는 Entra의 무료 기능입니다. |

## 3. 수행 내용과 실제 값

### 3-1. 테넌트·도메인·관리자 역할

**GUI 경로**: M365 관리 센터 > 사용자 > 활성 사용자 → Entra 관리 센터 > Entra ID > 개요 → 내 피드의 "역할 정보 보기" > 활성 할당 탭

**PowerShell(Cloud Shell, 읽기 전용)**: Graph `organization`, `domains`를 조회해 화면 값과 맞췄습니다.

```powershell
$o = ((Invoke-AzRestMethod -Uri https://graph.microsoft.com/v1.0/organization).Content | ConvertFrom-Json).value[0]
"$($o.displayName) / $($o.tenantType) / $($o.countryLetterCode)"
((Invoke-AzRestMethod -Uri https://graph.microsoft.com/v1.0/domains).Content | ConvertFrom-Json).value | Select id,isDefault,isVerified
```

| 항목 | 조회한 값 |
|---|---|
| 테넌트 종류 | AAD, 국가 코드 SG |
| 도메인 | 1개(기본 도메인, 확인됨, 인증 방식 Managed, 페더레이션 열 비어 있음) |
| 개요 카드 | 사용자 20 · 그룹 9 · 애플리케이션 0 · 디바이스 1 |
| 라이선스 | Microsoft Entra ID P2 |
| 내 역할 | 전역 관리자, 범위=테넌트, 멤버 자격=직접, 상태=Active, 종료=영구 |
| 경고 카드 | 레거시 MFA/SSPR 정책에서 인증 방법 정책으로 마이그레이션하라는 안내 |

- **의미**: 관리자 계정 하나가 전역 관리자를 **영구**로 쥐고 있습니다. 운영 환경이라면 상시 권한(영구 활성)은 줄이고 필요할 때만 올려 쓰는 방식(적격 할당)을 권합니다. (문서: [PIM 구성](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-configure))
- 가이드는 "관리 센터 6종"을 언급하지만 본문에 목록이 없어, 10/19에 접속을 확인한 포털은 M365 · Entra · Azure 3개입니다. 10/23에는 Teams · SharePoint · Exchange · Purview 관리 센터도 직접 열어 값을 조회했습니다(조회). 다만 가이드의 6종이 정확히 어느 것인지는 **확인 불가**입니다(시도: 가이드 본문에서 목록 찾기, 사유: 본문에 목록이 없음, 확인 사항으로 남김).

### 3-2. MFA와 보안 기본값

**GUI 경로**: Entra ID > 인증 방법 > 활동 > 사용자 등록 세부 정보 (영문 문서 표기: Entra ID > Authentication methods > Activity. 10/19에는 "보호 > 인증 방법 > 모니터링"으로 적었으나 현재 문서 기준 경로로 고침. 포털 메뉴 이름은 개편으로 달라질 수 있음) / Entra ID > 개요 > 속성 > 보안 기본값

| 항목 | 조회한 값 |
|---|---|
| 관리자 MFA | "다단계 인증 가능=사용 가능", 기본 방법=Authenticator 앱(푸시). 다른 사용자 대부분은 "불가능" |
| 보안 기본값 | "조직이 보안 기본값으로 보호됩니다" 표시 |
| Azure 리소스 액세스 관리 토글 | 아니요(권한 상승 안 됨) |
| **MFA 실제 로그인 동작** | **확인 불가** — 시도 방법: 로그인 프롬프트 동작 확인. 사유: 본인 계정의 인증 정보를 입력해야 하는 시험이라 하지 않음(10/23도 같음). 다음 확인 방법: 브라우저 InPrivate 창에서 관리자 계정으로 로그인해 프롬프트 확인 |

- **문제점**: "등록 가능"과 "실제로 로그인 때 프롬프트가 뜬다"는 다른 이야기입니다. 등록 상태만 읽고 "MFA 됨"이라고 쓰면 과장입니다. 그래서 동작 여부는 위 표처럼 사유를 적고 확인 불가로 남겼습니다.
- **이 값이 나중에 영향을 줍니다**: 보안 기본값이 켜져 있으면 장치 코드 로그인이 막혀서 Exchange Online 연결이 실패했습니다. 별도 글([트러블슈팅: AADSTS530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}))에 원인과 해결 방안을 정리했습니다.
- 문서: 보안 기본값은 레거시 인증을 막고 관리자와 Azure 관리 접근에 MFA를 요구합니다. ([Security defaults](https://learn.microsoft.com/entra/fundamentals/security-defaults))

### 3-3. 라이선스(SKU)와 서비스 플랜

**GUI 경로**: M365 관리 센터 > 청구 > 라이선스 > 구독 탭 → 제품 이름 클릭 → 사용자 선택 → 툴바 "앱 및 서비스 관리" 패널(저장하지 않고 X로 닫음)

```powershell
$r = (Invoke-AzRestMethod -Uri https://graph.microsoft.com/v1.0/subscribedSkus).Content | ConvertFrom-Json
$r.value | Select skuPartNumber,@{n='구매';e={$_.prepaidUnits.enabled}},@{n='사용';e={$_.consumedUnits}},capabilityStatus
$r.value.servicePlans | Select servicePlanName,provisioningStatus
```

![사전작업 점검 결과 요약: 테넌트·관리자, 라이선스, Azure 구독, 주의]({{ "/assets/images/2026/10/prework-summary.png" | relative_url }})
*그림 1. 점검 결과 요약*

![Microsoft 365 관리 센터 라이선스 화면. Microsoft 365 E5 Developer SKU V2가 20/25로 표시됨]({{ "/assets/images/2026/10/prework-licenses.png" | relative_url }})
*그림 2. 라이선스 화면 (빨간 상자: 할당 20/25, 계정 정보는 가림)*

| 항목 | 조회한 값 |
|---|---|
| SKU | DEVELOPERPACK_V2_E5 (Microsoft 365 E5 Developer SKU V2, Windows·오디오 회의 제외) 1종 |
| 수량 | 구매 25 / 사용 20 / 남음 5, 상태 Enabled |
| 서비스 플랜 | 이름으로 추린 12개 모두 Success — Teams, Entra ID P2, Insider Risk Management, Communication Compliance, Records Management, Advanced Auditing, Data Investigations, MIP 계열 |
| 서비스 목록 위치 | 사용자 선택 후 "앱 및 서비스 관리" 패널. 회색 항목은 "조직 수준에서 할당"되어 사용자별로 못 끔 |
| **제품 상세 탭** | **라이선스, 오류 및 문제 2개뿐 — 가이드의 "앱" 탭 없음** |

- **문제점 1 — 가이드와 화면이 다릅니다.** 가이드가 안내한 "제품 상세 > 앱 탭"은 이 화면에 없었습니다. **해결 방안**: 사용자를 먼저 고른 뒤 "앱 및 서비스 관리"로 들어가는 경로를 실제 경로로 기록하고, 가이드 문구 수정 여부는 확인 사항으로 남겼습니다.
- **문제점 2 — 좌석이 5개뿐입니다.** 직접 할당으로 사용자를 몇 명 더 만들면 바로 25/25가 됩니다. 그룹 라이선스 실습(D2)에 쓸 좌석이 필요하므로, 사용자 생성 계획(5명)과 좌석이 충돌할 수 있다는 점을 미리 확인 사항으로 올렸습니다.
- 12개 서비스 플랜은 "이름 필터로 추린 목록"이며 **전체 목록이 아닙니다.** 전체 서비스 플랜 이름은 [서비스 플랜 참조](https://learn.microsoft.com/entra/identity/users/licensing-service-plan-reference)에 있습니다(문서, 이번 글에서 URL 재검증은 못 함 → 목록 내용은 **확인 불가**, 사유: 이 글을 쓰며 해당 문서를 다시 열어 보지 않음).
- 근거: 라이선스 할당과 앱 켜기·끄기 ([Assign licenses to users](https://learn.microsoft.com/microsoft-365/admin/manage/assign-licenses-to-users)), 개발자 샌드박스(E5, 25개, 개발 활동이 있으면 자동 갱신) ([Developer Program 시작하기](https://learn.microsoft.com/office/developer-program/microsoft-365-developer-program-get-started), [FAQ](https://learn.microsoft.com/office/developer-program/microsoft-365-developer-program-faq))

### 3-4. Azure 구독 · 지출 한도 · 할당량 · 역할

**GUI 경로**: portal.azure.com > 구독 > (구독 이름) > 개요 / 액세스 제어(IAM) > 액세스 권한 확인·역할 할당 / 설정 > 사용량 및 할당량(공급자=Compute, 검색 "Korea Central")

```powershell
Get-AzSubscription | % { "$($_.Name) | $($_.State) | QuotaId=$($_.SubscriptionPolicies.QuotaId) | SpendingLimit=$($_.SubscriptionPolicies.SpendingLimit)" }
Get-AzRoleAssignment | Select DisplayName,SignInName,RoleDefinitionName,Scope,ObjectType | Format-Table -AutoSize
Get-AzVMUsage -Location koreacentral | ? { $_.Name.Value -in 'cores','standardBSFamily','standardDSv5Family' } | Select @{n='Name';e={$_.Name.Value}},CurrentValue,Limit
```

| 항목 | 조회한 값 |
|---|---|
| 구독 수 / 상태 | 1개, Enabled(활성) |
| 구독 유형 | QuotaId = PayAsYouGo_2014-09-01 (종량제) |
| 지출 한도 | **Off(해제)** |
| 부모 관리 그룹 | Tenant Root Group, 현재 비용 0.00 |
| 내 역할 | Owner(구독 범위, 영구 활성). Owner가 1건 더 있음(서비스 사용자, 10/23 조회: 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 2026-08-23(테넌트 생성 시점), 앱 소유 조직은 외부. 용도는 **확인 불가**(시도: 서비스 사용자 상세 열기, 사유: 설명 항목이 비어 있음)) |
| vCPU(Korea Central) | 전체 0/10, BS 계열 0/10, DSv5 계열 0/0. 다수 계열 0/10, 일부(Confidential 등) 0/0 (표기는 "현재 사용/한도" 순서: 0/10 = 사용 0, 한도 10) |
| 리소스 그룹 수 | 1개(Southeast Asia) |

- **문제점**: 종량제인데 지출 한도가 꺼져 있으면, 리소스를 잘못 만들었을 때 비용이 그대로 청구될 수 있습니다. 문서에도 종량제 구독에는 지출 한도 기능이 없다고 적혀 있습니다. ([Spending limit](https://learn.microsoft.com/azure/cost-management-billing/manage/spending-limit))
- **해결 방안(원칙)**: 가이드의 "비용 발생 금지" 규칙대로 **VM은 만들지 않고**, 리소스 그룹처럼 비용이 없는 객체만 만들기로 했습니다. 할당량이 부족해서가 아닙니다. 위 값처럼 지역 전체와 BS 계열은 한도 10에 사용 0이라 vCPU 여유가 있고, 한도가 0인 것은 DSv5 등 일부 계열뿐입니다. VM을 만들지 않은 이유는 "비용 발생 금지" 원칙입니다.
- vCPU 할당량은 지역별·VM 계열별로 따로 걸립니다. ([Regional quota](https://learn.microsoft.com/azure/quotas/regional-quota-requests), [VM quotas](https://learn.microsoft.com/azure/virtual-machines/quotas))
- 구독과 테넌트 관계 ([구독이 디렉터리에 연결되는 방식](https://learn.microsoft.com/entra/fundamentals/how-subscriptions-associated-directory))

### 3-5. PowerShell 모듈

| 모듈 | Cloud Shell 조회 결과 |
|---|---|
| Az.Accounts | 5.5.3 발견 |
| MicrosoftTeams | 8.0.0 발견 |
| Microsoft.Graph | 발견되지 않음(통합 모듈만 없다는 뜻. 문서상 Cloud Shell에는 하위 모듈 8개가 미리 설치됨: Applications, Authentication, Groups, Identity.DirectoryManagement, Identity.Governance, Identity.SignIns, Users.Actions, Users.Functions. 이 테넌트의 Cloud Shell에서 하위 모듈을 따로 조회한 값은 없음 → **확인 불가**, 사유: 이번 조회는 통합 모듈 이름만 확인) |
| SharePoint Online 관리 모듈 | 발견되지 않음 |

- **해결 방안**: 필요한 Graph 하위 모듈이 없을 때는 `Invoke-AzRestMethod`로 Graph REST를 직접 호출하면 같은 조회가 됩니다. 이후 모든 PowerShell 검증은 이 방식으로 했습니다.

## 4. 보완 항목 4가지 (제출 전 확인용)

### 4-1. 메시지 센터 ↔ Planner 동기화

- **GUI 경로**: 관리 센터 > 상태 > 메시지 센터 > "Planner 동기화" 패널(설정 버튼은 누르지 않고 닫음)
- **조회**: 메시지 451개. 패널에 "메시지 센터 게시물을 Planner와 동기화, 제품·범주 선택, 계획·버킷으로 이동" 안내와 "동기화 설정" 버튼이 있음. 이미 동기화 중인지 구분하는 표시는 없음.
- **10/23 갱신**: 10/19에는 Plan 생성이 변경이라 하지 않았습니다. 10/23에 개발용 샌드박스에서 변경이 허용되어 Plan(MC-Tracking)과 Bucket(MC-Bucket-01)을 실제로 만들었고 생성에 성공했습니다(조회). 동기화는 설정하지 않아 미설정 상태입니다.

### 4-2. Log Analytics 작업 영역 생성 가능 여부와 비용 조건

- **GUI 경로**: 포털 상단 검색창에 "Log Analytics 작업 영역" → 목록 → 만들기 > 기초 탭(입력 없이 닫음) / 구독 > 설정 > 리소스 공급자
- **조회**: 작업 영역 0개. 필수 입력은 구독·리소스 그룹·이름·지역(기본 East US). 공급자 상태는 아래 표.

| 리소스 공급자 | 상태 |
|---|---|
| Microsoft.Insights | NotRegistered |
| Microsoft.OperationalInsights | NotRegistered |
| Microsoft.Management | NotRegistered |
| Microsoft.Consumption | Registered |
| Microsoft.Compute | Registered |
| 예산(Budget) | 0개 |

- **문제점**: 직접 주소(URL)로 목록·만들기 화면을 열면 로딩이 멈추고 PageLoadTimeout 오류가 한 번 났습니다. **해결 방안**: 포털 검색창으로 들어가면 정상 로딩됩니다.
- **판단**: 공급자 등록은 구독 설정 변경이므로 팀장 승인 전에는 하지 않았습니다. 10/23에 리소스 공급자 Microsoft.OperationalInsights와 Microsoft.Insights를 등록해 두 개 모두 Registered가 되었습니다(조회, 비용 없음). Log Analytics 작업 영역 자체는 비용이 들 수 있어 만들지 않았으므로, 작업 영역 생성 성공 여부는 **확인 불가**입니다(사유: 비용 항목).

### 4-3. 구독 이동 정책과 관리 그룹 계층 보호

- **GUI 경로**: 구독 목록 > 툴바 "정책 관리" / 포털 검색 "관리 그룹"
- **조회**: "Microsoft Entra ID에서 나가는 구독", "들어오는 구독" 모두 "어떤 사용자(승격된 전역 관리자 제외)도 허용하지 않음(권장)"이 선택되어 있고 라디오 버튼은 회색(비활성). PowerShell로도 두 값이 True, 예외 주체 0이었습니다.
- 관리 그룹 개요: 그룹 1개 / 구독 1개(Tenant Root Group > 구독). 하단에 "디렉터리 관리자로 등록되었지만 루트 관리 그룹에 액세스할 권한이 없다"는 메시지.
- **문제점**: 관리 그룹의 계층 보호 설정은 REST로 읽으면 HTTP 403(settings/read 권한 없음)이라 **당시에는 현재 값을 읽지 못했습니다.** **해결 방안**: 권한 상승(Elevate access)이 필요하므로 팀장 확인 사항으로 올렸고, 10/22 D4에서 제가 직접 토글을 켜서 전·후를 확인했습니다. 10/23에는 Elevate를 켠 상태에서 포털 토큰을 갱신하자 값을 읽었습니다(기본 관리 그룹 Tenant Root Group, 계층 보호 Off, 조회. [트러블슈팅 글]({{ "/m365/troubleshooting/mg-settings-403-elevate-refresh/" | relative_url }})). ([D4 글]({{ "/m365/readiness-d4-azure-structure/" | relative_url }}))
- 문서: 루트 관리 그룹은 기본적으로 아무도 접근 권한이 없고 전역 관리자만 상승할 수 있습니다. ([Management groups 개요](https://learn.microsoft.com/azure/governance/management-groups/overview))

### 4-4. 추가 Azure 구독 생성 가능 여부

- **조회**: 접근 가능한 청구 범위 0건, 청구 프로필 없음, 청구 계정 1개(유형 칸이 비어 있음).
- **확인 불가**: 청구 계정 유형, 내 청구 역할, 결제 수단 필요 여부. 시도: 10/19에 이어 10/23에도 청구 범위를 조회했으나 0건이었습니다. 사유: 청구 범위에 접근할 권한이 없고, 역할을 부여받는 것은 보안 변경이라 하지 않았습니다. 그래서 "추가 구독을 만들 수 있는가"는 **판단 불가**로 남겼습니다. 가이드의 안내대로 만들 수 없으면 팀장에게 알려야 하므로 확인 사항으로 올렸습니다.

## 5. 한눈에 보는 결과: 문서 기준 vs 실제 값

| 구분 | 문서/가이드가 말하는 것 | 이 테넌트에서 읽은 값 | 판정 |
|---|---|---|---|
| 제품 상세 구성 | 앱 탭에서 서비스 목록 | 라이선스·오류 및 문제 탭뿐 | 차이 있음(조회) |
| 라이선스 좌석 | 기록상 18/25 | 20/25 | 차이 있음 → **10/23 해소**: 10/14 이전 17명 + 10/14 1명 + 10/16 2명 = 20명. 이전 기록은 10/14~15 시점 값으로 보임 |
| 지출 한도 | 종량제는 지원하지 않음(문서) | Off | 일치(조회+문서) |
| 구독 이동 정책 | 기본 권장 값은 "허용하지 않음" | 나가는/들어오는 모두 허용하지 않음 | 일치(조회) |
| 루트 관리 그룹 | 기본적으로 접근 권한 없음(문서) | "볼 수 있는 권한 없음" 안내 | 일치(조회+문서) |
| MFA | 등록 후 로그인 때 요구 | 등록 가능 상태만 확인 | 동작 **확인 불가**(사유는 3-2 표) |

## 6. 운영 판단에 쓰는 요점

- 영구 전역 관리자 1명 + 비상 계정 없음은 위험 신호입니다(10/22 측정 글에서 다룹니다).
- 보안 기본값은 간편하지만 장치 코드 로그인을 막으므로, 스크립트 연결 방식을 먼저 정해야 합니다.
- 비용이 나갈 수 있는 구독(지출 한도 Off)에서는 "무엇을 만들지 않는다"를 규칙으로 먼저 정합니다.

## 7. 아직 모르는 것

- 실제 MFA 로그인 프롬프트 동작(확인 불가, 인증 정보 입력이 필요해 시도하지 않음)
- 구독 Owner 서비스 사용자의 용도(이름은 10/23에 확인, 용도는 확인 불가)
- 관리 그룹 설정의 현재 값 → 10/23에 확인함(Tenant Root Group, 계층 보호 Off)
- 청구 계정 유형과 추가 구독 생성 가능 여부
- 라이선스 18/25 → 20/25 차이의 원인 → 10/23에 해소(위 5절 표)

> 오늘 입력한 PowerShell 원문은 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 출력 값은 실제와 같습니다.

## 담당별 기록

이 글은 유재홍이 실습·측정한 내용입니다. 같은 주제에서 대원·현준이 맡은 부분은 각자 직접 채웁니다(칸만 마련).

| 담당 | 기록 | 상태 |
|---|---|---|
| 유재홍 | 이 글의 실습·측정·정리 | 작성함 |
| 대원 | (대원이 맡은 부분을 여기에 직접 작성) | 작성 대기 |
| 현준 | (현준이 맡은 부분을 여기에 직접 작성) | 작성 대기 |
