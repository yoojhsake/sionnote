---
title: "[Study] M365 관리 센터: 라이선스, 도메인, 관리자 역할"
date: 2026-10-31 10:06:00 +0900
categories: [study]
phase: 2단계 Microsoft 365
seq: 1
tags: [Study, M365, License, SKU, Service plan, Custom domain, Admin roles]
excerpt: "license를 할당하는 순간 켜지는 건 service plan입니다. SKU, 도메인 레코드, 관리자 역할을 관리 센터에서 짚어 봅니다"
---

License 할당은 CAL 부여와 비슷해 보이지만, 할당하는 순간 서비스가 바로 프로비저닝된다는 점이 다릅니다. 이번 주를 마치면 SKU와 service plan, 도메인 DNS 레코드, 관리자 역할을 관리 센터에서 직접 짚어 볼 수 있습니다.

## 요약

- license를 할당하면 그 안의 service plan 단위로 서비스가 바로 켜짐
- 그룹 기반 licensing과 dynamic group을 함께 쓰면 입사·이동 때 license가 따라감
- Global Administrator는 5명 미만으로 두고 나머지는 용도별 역할로 위임함

12주 학습 로드맵의 5주차입니다. 이전 글은 [4주차 인증 보안: MFA, 조건부 액세스, PIM]({{ "/study/auth-security-mfa-ca-pim/" | relative_url }}), 다음 글은 [6주차 Exchange Online]({{ "/study/exchange-online-basics/" | relative_url }})이고, 전체는 [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에서 볼 수 있습니다.

---

## 전체 내용

### 1. 이번 주 용어

Microsoft 365 admin center, Subscription, SKU, License, Service plan, Group-based licensing, Custom domain, DNS records(MX, TXT, CNAME), SPF, DKIM, DMARC, Admin roles, Service health, Message center, Usage reports

SPF, DKIM, DMARC는 [6주차 Exchange Online]({{ "/study/exchange-online-basics/" | relative_url }})에서 자세히 봅니다.

### 2. 개념 설명

하나의 license(SKU)는 여러 service plan(Exchange Online, SharePoint Online, Teams 등)의 묶음이고, 사용자별로 일부 plan만 끌 수 있습니다. 실제 테넌트에서 Planner plan을 껐다 켠 기록은 [M365 구조 실습]({{ "/m365/d1-m365-structure/" | relative_url }})에 있습니다.

Group-based licensing은 그룹에 할당한 license가 멤버에게 자동 적용되는 방식으로, Entra ID P1 이상(문서상 Office 365 Enterprise E3, Office 365 A3, Office 365 GCC G3 이상도 가능)이 필요합니다([Microsoft 365 Apps 라이선스 개요](https://learn.microsoft.com/microsoft-365-apps/licensing-activation/overview-licensing-activation-microsoft-365-apps#assign-and-manage-licenses)). 동적 그룹에 E5 라이선스를 준 실습은 [Identity 구조 실습]({{ "/m365/d2-identity-groups/" | relative_url }})에 있습니다.

Custom domain을 연결할 때는 도메인 소유를 TXT 레코드로 확인(verify)하고, 메일을 위해 MX, SPF(TXT), Autodiscover(CNAME), DKIM(CNAME) 레코드를 구성합니다.

관리자 역할은 Exchange Administrator, User Administrator 같은 용도별 역할로 위임하고, Global Administrator는 공식 모범 사례대로 5명 미만으로 둡니다.

운영자가 매일 여는 화면은 Service health(서비스 장애 현황), Message center(변경 예고), Usage reports(사용 현황)입니다.

### 3. 온프레미스로 번역하면

Message center는 "다음 달부터 서버 기능이 바뀝니다"를 알려 주는 벤더 공지 채널입니다. SaaS는 변경 일정을 고객이 정하지 못하니 이 화면을 읽는 습관이 있어야 합니다.

### 4. 실습 (GUI 우선)

1. M365 관리 센터(admin.microsoft.com) > 사용자 > 활성 사용자에서 사용자 한 명을 열어 license와 앱 탭을 봅니다. 어떤 service plan이 켜져 있는지 확인합니다.
2. 청구(Billing) > 구독(Your products)에서 license 총 수량과 할당 수량을 확인합니다.
3. 설정(Settings) > 도메인(Domains)에서 도메인 상태와 필요한 DNS 레코드 목록을 확인합니다.
4. 역할(Roles) > 역할 할당에서 관리자 역할 목록과 Global Administrator 수를 확인합니다.
5. 상태(Health) > 서비스 상태(Service health)와 메시지 센터(Message center)를 열어 최근 항목 세 개를 읽어 봅니다.

GUI에서 본 수량은 PowerShell(Microsoft Graph)로 맞춰 봅니다.

```powershell
Connect-MgGraph -Scopes "Organization.Read.All","User.Read.All"
Get-MgSubscribedSku |
  Select-Object SkuPartNumber, ConsumedUnits, @{n='Total'; e={$_.PrepaidUnits.Enabled}}
Get-MgUserLicenseDetail -UserId "user@contoso.com" |
  Select-Object SkuPartNumber
```

<details markdown="1">
<summary>화면으로 경로 따라가기: 사용자, 라이선스, 도메인, 역할, 서비스 상태 (그림 5장)</summary>

![활성 사용자 목록. 표시 이름, 사용자 이름, 라이선스 열]({{ "/assets/images/2026/11/guide-m365-users.png" | relative_url }})

*그림 1. Microsoft 365 관리 센터(admin.microsoft.com) > 사용자 > 활성 사용자. 표시 이름, 사용자 이름, 라이선스 열이 있고, 위쪽 도구 모음에서 사용자 추가, 다단계 인증, 암호 초기화를 합니다. 사용자 이름(로그인 계정)은 가렸습니다.*

![라이선스 화면. 제품별 사용 가능한 라이선스와 할당된 라이선스]({{ "/assets/images/2026/11/guide-m365-licenses.png" | relative_url }})

*그림 2. M365 관리 센터 > 청구 > 라이선스. 제품별로 사용 가능한 라이선스 수와 할당된 라이선스(예: 17/25)가 나옵니다. 제품 이름을 눌러 사용자나 그룹에 할당합니다.*

![도메인 화면. 도메인 이름과 상태]({{ "/assets/images/2026/11/guide-m365-domains.png" | relative_url }})

*그림 3. M365 관리 센터 > 설정(Setup) > 도메인(Domains). 도메인별 상태가 나옵니다. 이 샌드박스는 기본 onmicrosoft.com 도메인 하나뿐이고 "정상"입니다. 도메인 이름은 가렸습니다.*

![역할 할당 화면. Microsoft Entra ID, Exchange, Intune, 청구 탭과 역할 목록]({{ "/assets/images/2026/11/guide-m365-roles.png" | relative_url }})

*그림 4. M365 관리 센터 > 역할 > 역할 할당. 위쪽 탭이 Microsoft Entra ID, Exchange, Intune, 청구로 나뉘고, 아래에 관리자 역할 이름과 설명, 범주(공동 작업, 읽기 전용)가 나옵니다.*

![서비스 상태 화면. Microsoft이 처리 중인 활성 문제 목록]({{ "/assets/images/2026/11/guide-m365-health.png" | relative_url }})

*그림 5. M365 관리 센터 > 상태(Health) > 서비스 상태. 개요 탭에 Microsoft가 처리 중인 활성 문제와 영향을 받는 서비스가 나오고, 문제 기록과 보고된 문제 탭이 이어집니다.*

화면은 설정을 바꾸지 않고 샌드박스 테넌트에서 열어 캡처했습니다. 테넌트 이름과 ID, 계정, IP는 가렸고, 라이선스와 지역에 따라 메뉴 이름과 값은 다를 수 있습니다.

</details>

### 5. 전문가처럼 말하기

> "License는 SKU 단위로 사고, 실제로 켜지는 건 service plan입니다. 그룹 기반 licensing과 dynamic group을 같이 쓰면 joiner, mover, leaver 때 license가 자동으로 따라갑니다."
>
> "관리자 권한은 Global Administrator를 최소로 두고 Exchange Administrator처럼 용도별 role로 위임합니다."

### 6. 자가 점검

<details markdown="1">
<summary>자가 점검 문제와 답 펼쳐 보기 (4문항)</summary>

- [ ] SKU와 service plan의 관계를 설명할 수 있다.
    - 답: SKU(license) 하나가 여러 service plan의 묶음이고, 실제로 켜지는 것은 service plan입니다. 사용자별로 일부 plan만 끌 수 있습니다.
- [ ] Group-based licensing의 장점과 필요 라이선스를 말할 수 있다.
    - 답: 그룹에 할당하면 멤버에게 자동 적용되고, dynamic group과 쓰면 joiner, mover, leaver 때 license가 따라갑니다. Entra ID P1 이상(또는 Office 365 E3, A3, G3 이상)이 필요합니다.
- [ ] 도메인을 연결할 때 필요한 DNS 레코드 종류와 용도를 말할 수 있다.
    - 답: TXT는 도메인 소유 확인(verify)용입니다. 메일을 위해서는 MX, SPF(TXT), Autodiscover(CNAME), DKIM(CNAME)을 구성합니다.
- [ ] Message center를 매일 확인해야 하는 이유를 설명할 수 있다.
    - 답: SaaS는 변경 일정을 고객이 정하지 못하므로, 벤더의 변경 예고를 매일 읽어야 대비할 수 있습니다.

</details>

### 7. 영상과 자료 (한글 우선)

- 한글: 확인 불가(시도: 유튜브 검색, 사유: M365 관리자 센터를 다룬 한글 영상을 찾지 못함). Microsoft Learn(한국어)의 Microsoft 365 관리 센터 문서를 먼저 읽으세요.
- 영문 보완: [Microsoft 365 Admin Centre, Intune, EntraID, Exchange 연동 개요](https://www.youtube.com/watch?v=o8bdHkxw-Es) (Tech's World, 54분). 라이선스, 테넌트, Entra 같은 관리 센터 메뉴 위주로 설명하고, 제목과 달리 Intune과 Exchange는 짧게 다룹니다.
