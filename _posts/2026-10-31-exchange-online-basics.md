---
title: "[Study] Exchange Online: 사서함, 메일 흐름, 하이브리드"
date: 2026-10-31 10:07:00 +0900
categories: [study]
phase: 2단계 Microsoft 365
seq: 2
tags: [Study, M365, Exchange Online, EOP, Mail flow, SPF, DKIM, DMARC, Exchange hybrid]
excerpt: "DAG 대신 정책을 다룹니다. MX → EOP → 사서함 흐름, SPF와 DKIM, DMARC, Exchange hybrid의 전제를 정리합니다"
---

Exchange Online에서는 DAG도 Edge Transport도 직접 구성하지 않고, 메일 흐름과 정책 구성이 업무의 중심이 됩니다. 이번 주를 마치면 MX → EOP → 사서함 흐름, SPF와 DKIM, DMARC, Exchange hybrid의 전제를 설명할 수 있습니다.

## 요약

- Microsoft가 서버를 운영하므로 DAG나 데이터베이스는 관리하지 않음. mail flow(MX → EOP → 사서함)와 정책, 권한 구성에 집중
- 외부 메일은 MX가 가리키는 EOP에서 악성코드, 스팸 검사 후 사서함으로. 파트너나 하이브리드 같은 특수 경로는 Connector로 정의
- 그룹은 Distribution group(메일 배포), Mail-enabled security group(메일 배포 + 권한), Microsoft 365 group(협업 전체)으로 구분
- 메일 인증은 SPF(발신 허용 서버 선언), DKIM(서명), DMARC(SPF·DKIM 실패 시 처리 정책)
- Exchange hybrid는 온프레미스 Exchange를 두고 일부 사서함만 Exchange Online에 두는 구성. HCW로 구성하고 Entra Connect 동기화가 전제

12주 학습 로드맵의 6주차입니다. 이전 글은 [5주차 M365 관리 센터]({{ "/study/m365-admin-center-basics/" | relative_url }}), 다음 글은 [7주차 SharePoint·OneDrive·Teams]({{ "/study/sharepoint-onedrive-teams-structure/" | relative_url }})이고, 전체는 [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에 있습니다.

---

## 전체 내용

### 1. 이번 주 용어

Exchange Online, EOP(Exchange Online Protection), Mailbox types(User, Shared, Room, Equipment), Distribution group, Mail-enabled security group, Microsoft 365 group, Accepted domain, Mail flow rule(transport rule), Connector, MX, SPF, DKIM, DMARC, Autodiscover, Exchange hybrid, HCW(Hybrid Configuration Wizard), Message trace, Quarantine, Retention policy, Litigation hold

### 2. 개념 설명

#### 메일이 들어오는 길

외부에서 오는 메일은 MX 레코드가 가리키는 EOP를 거쳐 악성코드, 스팸 검사를 받은 뒤 사서함으로 전달됩니다. 파트너 전용 경로나 하이브리드 같은 특수 경로는 **Connector**로 정의합니다.

#### 받는 사람과 그룹

받는 사람에는 사용자 사서함, Shared mailbox(로그인 없이 공유), Room·Equipment mailbox(자원 예약)가 있습니다. 그룹은 Distribution group(메일 배포), Mail-enabled security group(메일 배포 + 권한), Microsoft 365 group(협업 전체)을 구분해 씁니다.

#### 메일 인증

SPF는 발신 허용 서버를 DNS에 선언하고, DKIM은 서명하며, DMARC는 SPF나 DKIM이 실패했을 때의 처리 정책을 선언합니다. 도메인에 넣는 DNS 레코드 목록은 [5주차 M365 관리 센터]({{ "/study/m365-admin-center-basics/" | relative_url }})에서 봤습니다.

#### Exchange hybrid

온프레미스 Exchange를 두고 일부 사서함만 Exchange Online에 두는 구성입니다. HCW로 구성하고, 사서함은 이동(move)으로 옮깁니다. Entra Connect 동기화가 전제입니다([하이브리드 ID]({{ "/study/hybrid-identity-study/" | relative_url }}) 참고).

#### 관리 도구와 규정 준수

관리는 Exchange admin center(admin.exchange.microsoft.com)와 PowerShell(ExchangeOnlineManagement 모듈의 `Connect-ExchangeOnline`)로 합니다.

보존(retention) 정책은 Microsoft Purview에서 만들고, Litigation hold는 사서함마다 켭니다. 메일 추적은 message trace로 합니다. 문서 기준으로 Litigation hold는 Exchange Online 사용자 사서함에 거는 hold이고, retention policy는 Microsoft Purview의 보존 기능입니다([Exchange 사서함 hold 유형](https://learn.microsoft.com/purview/edisc-hold-types-mailboxes#overview-of-exchange-mailbox-hold-types)). Litigation hold를 걸려면 사서함에 Exchange Online Plan 2 license(또는 Plan 1 + Exchange Online Archiving)가 필요합니다. PowerShell로는 `Set-Mailbox <username> -LitigationHoldEnabled $true`입니다([Place a mailbox on litigation hold](https://learn.microsoft.com/microsoft-365/admin/misc/create-litigation-hold-mac)).

### 3. 온프레미스로 번역하면

| Exchange Online | 온프레미스 Exchange |
|---|---|
| Mail flow rule | Transport rule |
| Connector | Receive/Send Connector |
| (Microsoft가 운영) | Edge Transport, DAG |

Transport rule은 그대로 Mail flow rule이고, Receive/Send Connector는 같은 이름의 Connector입니다. 달라진 점은 Edge Transport나 DAG처럼 인프라를 직접 구성하던 부분이 사라지고, **정책 구성**이 업무의 중심이 된다는 것입니다.

### 4. 실습 (GUI 우선)

1. Exchange 관리 센터 > 받는 사람(Recipients) > 사서함(Mailboxes)에서 사서함 유형을 확인합니다.
2. 메일 흐름(Mail flow) > 메시지 추적(Message trace) 화면의 필터를 확인합니다.
3. 메일 흐름 > 규칙(Rules)과 커넥터(Connectors) 화면을 읽습니다.
4. 메일 흐름 > 수락된 도메인(Accepted domains)을 확인합니다.

GUI에서 본 사서함 유형과 수락된 도메인을 PowerShell로 맞춰 볼 때는 다음을 씁니다.

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Connect-ExchangeOnline
Get-Mailbox -ResultSize 5 | Select-Object DisplayName, RecipientTypeDetails
Get-AcceptedDomain | Select-Object DomainName, DomainType
```

### 5. 전문가처럼 말하기

> "외부 메일은 MX가 EOP를 가리키고, EOP에서 anti-malware와 anti-spam 검사를 거쳐 사서함으로 들어옵니다. 하이브리드나 파트너 경로는 connector로 따로 정의합니다."
>
> "SPF, DKIM, DMARC를 모두 구성하고 DMARC 정책을 report only에서 quarantine, reject로 단계적으로 올립니다."

### 6. 자가 점검

- MX → EOP → 사서함 흐름을 그림 없이 말할 수 있다.
- Distribution group, Mail-enabled security group, Microsoft 365 group의 차이를 말할 수 있다.
- SPF, DKIM, DMARC의 역할을 각각 한 문장으로 말할 수 있다.
- Exchange hybrid가 무엇이고 무엇이 전제인지 말할 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (4문항)</summary>

- **메일 흐름**: MX 레코드가 EOP를 가리키고, EOP에서 anti-malware와 anti-spam 검사를 거친 메일이 사서함으로 전달됩니다.
- **그룹 3종**: Distribution group은 메일 배포, Mail-enabled security group은 메일 배포 + 권한, Microsoft 365 group은 협업 전체입니다.
- **메일 인증 3종**: SPF는 발신 허용 서버를 DNS에 선언, DKIM은 서명, DMARC는 SPF·DKIM 실패 시 처리 정책 선언입니다.
- **Exchange hybrid**: 온프레미스 Exchange를 두고 일부 사서함만 Exchange Online에 두는 구성으로, HCW로 구성합니다. Entra Connect 동기화가 전제입니다.

</details>

### 7. 영상과 자료 (한글 우선)

- 한글: 확인 불가(시도: 유튜브 검색, 사유: Exchange Online을 다룬 한글 영상을 찾지 못함). Microsoft Learn(한국어)의 Exchange Online 문서를 먼저 읽으세요.
- 영문 보완: [How to Use Exchange Online Admin Center](https://www.youtube.com/watch?v=J0OWaStDkMc), [Beginners Tutorial for Exchange Online & Microsoft 365 Administration (재생목록)](https://www.youtube.com/playlist?list=PLUZTRmXEpBy0W9bJNme2P9h5XiOnRIFUI), [Creating and Managing User Mailboxes](https://www.youtube.com/watch?v=yvhwHjNVMvw)
