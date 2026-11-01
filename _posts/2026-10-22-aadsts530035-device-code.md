---
title: "[Troubleshooting] Exchange Online 장치 코드 로그인이 AADSTS530035로 막힘"
date: 2026-10-22 10:10:00 +0900
categories: [m365, troubleshooting]
area: 로그인·권한
seq: 1
tags: [Exchange Online, PowerShell, Entra, 보안 기본값, AADSTS530035, 조건부 액세스, 로그인 로그, 전체 기록]
excerpt: "Exchange 장치 코드 로그인이 530035로 막혔고, 로그인 로그로 보안 기본값 차단을 확정했습니다. 설정은 바꾸지 않았습니다."
---

`Connect-ExchangeOnline -Device`로 코드를 넣고 관리자 계정을 골랐는데 "이에 대한 액세스 권한이 없습니다"와 오류 코드 530035가 나왔습니다. 로그인 로그가 "Access has been blocked by security defaults."로 직접 기록해 원인을 보안 기본값으로 확정했고, 보안 기본값은 끄지 않았습니다.

## 요약

- 장치 코드 로그인은 Exchange와 Azure CLI 모두 보안 기본값에 막힘
- 보안 기본값을 끄지 말고 내 PC의 브라우저 대화형 로그인부터 시도해야 함
- 그 방식으로 실제 연결되는지와 감사 로그 수집 여부는 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면에서 직접 읽었고, Request Id, Correlation Id, IP도 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

- 하려던 일: Exchange Online PowerShell로 통합 감사 로그 수집 여부(`UnifiedAuditLogIngestionEnabled`)를 읽기 전용으로 확인
- 환경: Azure Cloud Shell(PowerShell 7, 브라우저가 없어 화면의 코드를 다른 브라우저 창에 넣는 device-code 방식 사용), 관리자 계정(전역 관리자), 클라우드 전용 샌드박스 테넌트
- 화면: 코드를 넣고 관리자 계정을 고르자 "이에 대한 액세스 권한이 없습니다"와 **오류 코드 530035**. 앱 Microsoft Exchange REST API Based Powershell, 디바이스 상태 Unregistered(조회). 계정이나 암호 오류가 아니라 액세스 단계에서 차단됨

```powershell
Connect-ExchangeOnline -Device
```

![로그인 후 이에 대한 액세스 권한이 없습니다 화면과 문제 해결 세부 정보. 오류 코드 530035]({{ "/assets/images/2026/10/530035-error.png" | relative_url }})
*그림 1. 오류 화면과 "추가 정보" 펼침(10/24 01:19경 같은 명령 `Connect-ExchangeOnline -Device`로 다시 재현해 선명하게 촬영. 위 카드와 아래 카드를 이어 붙인 그림이고 앱 이름은 Microsoft Exchange REST API Based Powershell, 오류 코드 530035. 계정, Request Id, Correlation Id, IP는 가림)*

### 2. 원인 및 분석

(가) 근거: 인증 오류 코드 표에서 AADSTS530035는 **BlockedBySecurityDefaults**이고, 보안 기본값은 device-code 흐름을 막으며 조건부 액세스 정책과 함께 쓸 수 없습니다(문서).

(나) 확인된 내용(조회)

- 보안 기본값: 켜짐(10/19 확인) / 조건부 액세스 정책: GUI 0개, Graph 조회는 HTTP 403(09:49)
- 로그인 로그(오류 코드 = 530035, 7일): 10/22 06:52:33 UTC Exchange 원격 PowerShell 실패 1건, 실패 이유 "Access has been blocked by security defaults.", 조건부 액세스 탭 Security Defaults / Block, 인증 요구 사항 단일 요소 인증
- 같은 Cloud Shell에서 Files.ReadWrite.All 범위로 `az login` 장치 코드 로그인: 10/23 07:45:57 UTC Microsoft Azure CLI도 530035, 같은 실패 이유와 Security Defaults(Block). 이 기록은 처음 조회 때는 목록에 없었고(반영 지연으로 추정) 나중에 같은 필터로 찾음
- 조건부 액세스 정책이 없어 "이 앱, 이 방식은 허용" 같은 예외를 만들 수 없음

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 9장)</summary>

![Microsoft Entra 조건부 액세스 정책 화면. 등록된 정책 없이 예시 템플릿만 표시됨]({{ "/assets/images/2026/10/ca-policies.png" | relative_url }})
*그림 2. 조건부 액세스 정책 화면 (상단 계정 정보는 가림)*

Graph 403의 원인 후보는 읽기 역할 부족과 토큰 범위 부족 두 가지입니다(아래 결론의 확인 불가 항목).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/10/aadsts530035-flow-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/10/aadsts530035-flow.png" | relative_url }}" alt="Cloud Shell의 device-code 로그인이 보안 기본값에 막혀 530035가 나오는 경로와 대안" loading="lazy"></picture>

*그림 3. 오류가 나온 경로와 대안*

오류 코드 표와 테넌트 상태는 정황이라, 실제 적용된 정책을 로그인 로그에서 읽었습니다.

![로그인 로그 기본 정보. 상태 실패, 오류 코드 530035, 실패 이유 보안 기본값에 의해 차단]({{ "/assets/images/2026/10/530035-signin-log-1.png" | relative_url }})
*그림 4. GUI 경로: Entra 관리 센터 > 모니터링 및 상태 > 로그인 로그 > 항목 열기 > 기본 정보 탭(10/22 06:52:33 UTC의 Microsoft Exchange 원격 PowerShell 로그인). 상태 실패, 로그인 오류 코드 530035, 실패 이유 "Access has been blocked by security defaults."가 보입니다. 요청 ID와 상관관계 ID는 가렸습니다.*

![로그인 로그 목록. 상태 실패로 거른 결과에 10/22 Exchange 원격 PowerShell과 10/23 Azure CLI 항목]({{ "/assets/images/2026/10/530035-signin-list.png" | relative_url }})
*그림 5. 같은 화면에서 상태를 "실패"로 거르고 날짜 범위를 지난 7일로 넓힌 목록(UTC 표시). 맨 아래 두 줄이 10/22 06:52:33의 Microsoft Exchange 원격 PowerShell과 10/23 07:45:57의 Microsoft Azure CLI입니다. 요청 ID와 계정 열은 가렸습니다.*

![로그인 로그 조건부 액세스 탭. Security Defaults, Block, 실패]({{ "/assets/images/2026/10/530035-signin-log-2.png" | relative_url }})
*그림 6. 같은 기록의 조건부 액세스 탭. 정책 이름 Security Defaults, 컨트롤 권한 부여 Block, 결과 실패. 적용된 것은 조건부 액세스 정책이 아니라 Security Defaults입니다.*

포털 밖 클라이언트 로그인이 전반적으로 같은 규칙에 막히는 것으로 보입니다(채널 403 쪽은 [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) 글).

![Azure CLI 장치 코드 로그인이 530035로 막힌 화면]({{ "/assets/images/2026/10/530035-azcli.png" | relative_url }})
*그림 7. Azure CLI 장치 코드 로그인(`az login --use-device-code`)의 530035 오류 화면(10/24 01:22경 재현해 선명하게 촬영, 위와 아래 카드를 이어 붙임, 앱 이름 Microsoft Azure CLI). 계정, 요청 ID, 접속 IP는 가렸습니다.*

![로그인 로그 기본 정보. Microsoft Azure CLI, 오류 코드 530035]({{ "/assets/images/2026/10/530035-azcli-signin-1.png" | relative_url }})
*그림 8. 10/23 07:45:57 UTC의 Azure CLI 로그인 실패 기록(기본 정보 탭). 로그인 오류 코드 530035, 실패 이유 "Access has been blocked by security defaults." 요청 ID와 상관관계 ID는 가렸습니다.*

![로그인 로그 조건부 액세스 탭. Security Defaults Block 실패]({{ "/assets/images/2026/10/530035-azcli-signin-2.png" | relative_url }})
*그림 9. 같은 기록의 조건부 액세스 탭. Security Defaults, Block, 실패.*

![로그인 로그 목록의 Azure CLI 행]({{ "/assets/images/2026/10/530035-azcli-signin-list.png" | relative_url }})
*그림 10. 상태 "실패" 필터(지난 24시간, UTC)의 목록. 맨 아래 줄이 Microsoft Azure CLI 실패이고, 위쪽 Azure Portal과 OfficeHome 실패 6건 중 첫 건을 열어 보니 오류 코드가 530035가 아니라 50197("Sorry, we could not find the user, please sign-in again.")였습니다(나머지 5건은 열어 보지 않음). 요청 ID와 계정 열은 가렸습니다.*

</details>

### 3. 결론

`보안 기본값 켜짐 + device-code 로그인 → 단일 요소 요청을 Security Defaults가 Block → 530035`

원인은 로그인 로그로 확정했고 설정은 바꾸지 않았습니다. PowerShell이 막힌 동안 Exchange 관리 센터(GUI)에서 사서함 20개(전부 사용자)와 Microsoft 365 그룹 9개는 읽었습니다(조회).

| 항목 | 오류 시점 | 지금 |
|---|---|---|
| 감사 기록 상태 | 확인 불가 | **확인 불가**(화면 오류, PowerShell 미연결) |
| 보안 기본값 | 켜짐 | 켜짐(변경 없음) |
| 조건부 액세스 정책 | 0개 | 0개(변경 없음) |
| 테넌트 설정 변경 | - | **없음** |

<details markdown="1">
<summary>확인 불가 항목 펼쳐 보기 (4건)</summary>

- **Graph 정책 조회에 필요한 최소 읽기 역할**
    - 시도 방법: 정책 목록을 Graph로 조회(HTTP 403), 문서에서 필요한 역할 확인
    - 막힌 이유: 확정할 근거를 찾지 못함. 403의 원인은 읽기 역할 부족과 토큰 범위 부족 두 후보로 나뉘고 가리지 못함
    - 다음 방법: 확인 사항으로 남김
- **통합 감사 로그 수집 여부(Exchange PowerShell)**
    - 시도 방법: `Connect-ExchangeOnline -Device` 장치 코드 로그인
    - 막힌 이유: 보안 기본값 때문에 AADSTS530035로 차단. 보안 기본값 변경은 보안 설정 변경이라 하지 않음
    - 다음 방법: 선택 A(내 PC의 브라우저 대화형 로그인) 등 다른 로그인 방식
- **Purview 감사 상태**
    - 시도 방법: Purview 감사 화면 열기, 감사 검색 화면 재방문
    - 막힌 이유: 화면이 "활동이 기록되고 있는지 확인하는 데 문제가 있다"는 오류를 계속 표시하고 검색 버튼이 회색(PowerShell은 같은 이유로 연결 불가).
    - "사용자 및 관리자 활동 기록 시작" 버튼은 누르지 않음
    - 다음 방법: PowerShell 연결이 가능해진 뒤 `Get-AdminAuditLogConfig`
- **브라우저 대화형 로그인(선택 A)이 실제로 되는지**
    - 시도 방법: 아래 권고방안 1의 순서로 계획
    - 막힌 이유: PC에서 실행하지 못함(PC 접속 불가)

</details>

### 4. 권고방안

1. 조치: 보안 기본값은 그대로 두고 **내 PC의 PowerShell**에서 `-Device` 없이 브라우저 대화형 로그인으로 연결합니다(설정 변경 없음). 보안 기본값이 막는 것은 레거시 인증과 장치 코드 흐름이라 MFA만 통과하면 될 가능성이 있습니다.
    1. `Connect-ExchangeOnline -UserPrincipalName 관리자계정` 실행 후 로그인 창에서 계정 선택, MFA 승인
    2. 연결되면 `Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled`, `Get-Mailbox -ResultSize 5` 실행 후 화면 캡처
2. 조치 후 확인: 위 명령 값이 나오고 530035가 다시 나오지 않으면 해결입니다. 실패하면 오류 번호를 공식 표에서 찾고 Entra 로그인 로그의 조건부 액세스 탭을 봅니다.
3. 자동화나 스크립트용 로그인은 사람 계정의 대화형 로그인 대신 **앱 등록 + 인증서/관리 ID** 방식으로 설계합니다.
4. 하지 말아야 할 것: 막혔다고 보안 기본값을 끄는 것. 하나뿐인 기본 보호(MFA 등록 요구 등)가 사라지고, 문서도 보안 정책을 꺼서 피하지 말라고 안내합니다(문서). 비상(break-glass) 계정도 없어(조회) 되돌릴 계정이 없어질 수 있습니다.
5. 꼭 바꿔야 한다면(선택 B: 보안 기본값을 끄고 조건부 액세스로 전환) 변경 이력을 먼저 쓰고 비상 계정을 둔 뒤 아래 순서로 진행합니다. 선택 A, B의 실행 결과는 이 글에 기록하지 않았습니다.

<details markdown="1">
<summary>선택 B 순서 펼쳐 보기 (0~7, 8단계)</summary>

4번에서 보안 기본값을 끄면 MFA 강제 없이 노출되는 시간이 생기므로 3번에서 정책을 먼저 준비하고, 4~5번 사이를 짧게, 6번 원복까지 한 번에 진행합니다. 모든 단계는 변경 이력(언제, 무엇을, 전→후, 누가, 왜, 근거, 검증, 원복)으로 남깁니다.

- **0**: 시작 전 상태 기록: 보안 기본값 켜짐, 조건부 액세스 0개, 관리자 MFA 등록 상태 캡처
- **1**: 비상(break-glass) 계정 2개 생성, 전역 관리자 부여, 클라우드 전용 계정(문서: 비상 액세스 계정 권고)
    - 되돌리기 → 시험 후 삭제
- **2**: 비상 계정으로 로그인 가능한지 확인(보안 기본값이 켜져 있어 MFA 등록 요구가 나올 수 있음, 이 화면도 기록)
- **3**: 조건부 액세스 정책을 **보고 전용**으로 먼저 만들어 로그인 로그 영향 확인(관리자와 전체 사용자 MFA 요구, 비상 계정 제외)
    - 되돌리기 → 정책 삭제
- **4**: Entra ID > 개요 > 속성 > 보안 기본값 관리 > **사용 안 함** 저장
    - 되돌리기 → 아래 5
- **5**: 정책을 사용으로 전환하고 Exchange 연결을 다시 시도, 결과 캡처
- **6**: **원복**: 문서에 따르면 조건부 액세스 정책이 하나라도 있으면(꺼짐, 보고 전용 포함) 보안 기본값을 켤 수 없어서,
    - 시험용 정책을 모두 삭제한 뒤 보안 기본값을 다시 사용으로 저장
- **7**: 원복 확인: 보안 기본값 켜짐, 정책 0개를 읽기 전용으로 확인 후 전·후 비교 기록

</details>

관련 글: [비공개·공유 채널 파일 403: 멤버십인가 토큰 범위인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (10건)</summary>

- 문서: AADSTS530035 = BlockedBySecurityDefaults
    - [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- 문서: 보안 기본값의 정의, device-code 흐름 차단, 조건부 액세스와의 관계
    - [Security defaults](https://learn.microsoft.com/entra/fundamentals/security-defaults)
- 문서: 530035 대응 시 보안 정책을 끄지 말라는 안내
    - [Agent 365 troubleshooting](https://learn.microsoft.com/microsoft-agent-365/developer/troubleshooting)
- 문서: 조건부 액세스 정책이 하나라도 있으면 보안 기본값을 켤 수 없음(원복 순서), 보안 기본값 끄는 경로, 비상 계정 권고
    - [Set up multifactor authentication for Microsoft 365](https://learn.microsoft.com/microsoft-365/admin/security-and-compliance/set-up-multi-factor-authentication?view=o365-worldwide#manage-conditional-access-policies), [Security defaults](https://learn.microsoft.com/entra/fundamentals/security-defaults#disabling-security-defaults)
- 조회: 오류 화면, 앱 이름, 디바이스 상태 (출처: Entra 로그인 화면)
- 조회: 조건부 액세스 0개, Graph 403 (출처: Entra 포털, Cloud Shell)
- 조회: 로그인 로그의 실패 이유 "blocked by security defaults", 조건부 액세스 탭 Security Defaults/Block (Exchange, Azure CLI 두 건)
    - 출처: Entra 로그인 이벤트
- 조회: Files 범위 `az login` 장치 코드 로그인도 530035 (출처: 로그인 화면)
- 조회: Exchange 관리 센터(GUI)에서 사서함 20개(전부 사용자), Microsoft 365 그룹 9개 (출처: Exchange 관리 센터)
- 확인 불가: 최소 읽기 역할, Exchange PowerShell 값, Purview 감사 상태
    - 시도, 사유, 다음 방법은 위 결론의 확인 불가 목록

</details>
