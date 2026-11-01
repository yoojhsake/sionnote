---
title: "[Study] SharePoint, OneDrive, Teams: 협업 서비스의 구조"
date: 2026-10-31 10:08:00 +0900
categories: [study]
phase: 2단계 Microsoft 365
seq: 3
tags: [Study, M365, SharePoint, OneDrive, Teams, External sharing, Microsoft Purview]
excerpt: "구성원은 그룹에서, 파일 권한은 SharePoint에서 봅니다. Team의 구성, 파일 저장 위치, 외부 공유 계층을 정리합니다"
---

Team의 구성원은 Microsoft 365 group에서, 파일 권한은 SharePoint에서 봐야 합니다. 이번 주를 마치면 Team이 무엇으로 묶여 있는지, 파일이 어디에 저장되는지, 외부 공유가 어느 단계에서 막히는지 설명할 수 있습니다.

## 요약

- 비공개·공유 채널 파일은 팀 사이트가 아닌 채널별 별도 사이트에 저장됨
- 고유 권한은 늘릴수록 관리가 어려우니 상위 권한 상속을 기본으로 둠
- 외부 공유는 테넌트 설정이 상한이라 사이트에서 허용해도 막힐 수 있음

12주 학습 로드맵의 7주차입니다.
이전 글: [6주차 Exchange Online]({{ "/study/exchange-online-basics/" | relative_url }}) · 다음 글: [8주차 Intune]({{ "/study/intune-device-management/" | relative_url }}) · [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

SharePoint Online, Site(Team site·Communication site), Hub site, OneDrive for Business, Microsoft 365 group, Team, Channel(Standard·Private·Shared), Owners·Members·Visitors, Sharing link(Anyone·People in your organization·Specific people), External sharing, Guest access, Permission inheritance, Sensitivity label, Retention label, DLP(Data Loss Prevention), Microsoft Purview

### 2. 개념 설명

Team은 Microsoft 365 group(구성원), SharePoint 팀 사이트(파일), Exchange 그룹 사서함이 묶인 패키지입니다.

- Standard channel의 파일은 팀 사이트의 SharePoint에, 채팅 파일은 OneDrive에 저장됩니다.
- Private channel과 Shared channel은 채널마다 별도의 SharePoint 사이트를 가집니다(문서: [Teams와 SharePoint 통합 개요](https://learn.microsoft.com/sharepoint/teams-connected-sites#teams-connected-sites-and-channel-types)). Standard channel만 팀 사이트 하나를 함께 쓰고 채널별 폴더로 나뉩니다.
- 실제 테넌트에서 조회한 기록은 [Teams 저장 구조 실습]({{ "/m365/d3-teams-storage/" | relative_url }})에 있습니다.

SharePoint 사이트는 Owners, Members, Visitors 그룹으로 권한을 부여하고, 문서 라이브러리와 파일은 기본적으로 상위 권한을 상속(inheritance)하며, 이와 다른 권한을 고유 권한(unique permissions)이라 합니다.

공유 링크는 Anyone(링크만 있으면 누구나), People in your organization, People with existing access, Specific people의 네 가지입니다. 외부 공유는 테넌트 > 사이트 > 링크의 계층 구조입니다.

데이터 보호인 Sensitivity label(분류·암호화), Retention label과 retention policy(보존·삭제), DLP(유출 방지)는 Microsoft Purview에서, 사이트와 Team은 SharePoint admin center와 Teams admin center에서 따로 관리합니다.

### 3. 온프레미스로 번역하면

| M365 | 온프레미스 |
|---|---|
| 팀 사이트 | 파일 서버의 부서 공유 폴더 |
| Owners·Members·Visitors | 폴더 ACL 그룹 |
| 공유 링크 | 임시 공유 URL |

접근 모델이 "폴더 경로"에서 "링크와 사이트 구성원"으로 바뀝니다.

### 4. 실습 (GUI 우선)

1. SharePoint 관리 센터 > 사이트 > 활성 사이트에서 사이트 목록과 유형을 봅니다.
2. 정책(Policies) > 공유(Sharing)에서 테넌트 수준의 외부 공유 설정을 읽기만 합니다.
3. Teams 관리 센터(admin.teams.microsoft.com) > 팀 > 팀 관리에서 Team 하나를 열어 Owners, Members, 채널 유형을 확인합니다.
4. 같은 Team에 연결된 SharePoint 사이트를 찾아 두 곳의 구성원이 같은지 비교합니다.

<details markdown="1">
<summary>화면으로 경로 따라가기: 활성 사이트, 공유 정책, 팀 관리 (그림 3장)</summary>

![SharePoint 관리 센터의 활성 사이트 목록]({{ "/assets/images/2026/11/guide-spo-sites.png" | relative_url }})

*그림 1. SharePoint 관리 센터 > 사이트 > 활성 사이트. 사이트 이름, URL, Teams 연결 여부, 채널 사이트 수, 사용된 저장소, 기본 관리자 열이 있습니다. 사이트 이름과 URL은 가렸습니다.*

![SharePoint 관리 센터의 공유 정책 화면. 외부 공유 수준 슬라이더]({{ "/assets/images/2026/11/guide-spo-sharing.png" | relative_url }})

*그림 2. SharePoint 관리 센터 > 정책 > 공유. 외부 공유 수준을 SharePoint와 OneDrive 각각 누구나, 신규 및 기존 게스트, 기존 게스트, 조직 내 사용자만의 네 단계로 정합니다. 이번 캡처에서는 값을 바꾸지 않았습니다.*

![Teams 관리 센터의 팀 관리 화면]({{ "/assets/images/2026/11/guide-teams-manage.png" | relative_url }})

*그림 3. Teams 관리 센터(admin.teams.microsoft.com) > Teams > 팀 관리(Manage teams). 위쪽에 사용자 요약(전체, 내부, 게스트)이 있고, 아래 목록에 팀별 채널 수, 소유자 수, 공개 범위, 상태가 나옵니다. 팀 이름은 가렸습니다.*

화면은 설정을 바꾸지 않고 샌드박스 테넌트에서 열어 캡처했습니다. 테넌트 이름과 ID, 계정, IP는 가렸고, 라이선스와 지역에 따라 메뉴 이름과 값은 다를 수 있습니다.

</details>

### 5. 전문가처럼 말하기

> "Team은 Microsoft 365 group을 membership backbone으로 하고 SharePoint 팀 사이트와 그룹 사서함이 붙은 구조입니다. 그래서 구성원 관리는 그룹에서, 파일 권한은 SharePoint에서 봐야 합니다."

### 6. 자가 점검

- Team을 이루는 세 가지 구성요소를 말할 수 있다.
- Standard channel과 Private channel의 파일 저장 위치 차이를 설명할 수 있다.
- 공유 링크 네 가지를 구분할 수 있다.
- 외부 공유 설정의 계층(테넌트 > 사이트 > 링크)을 설명할 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (4문항)</summary>

- **Team의 구성요소**: Microsoft 365 group, SharePoint 팀 사이트, Exchange 그룹 사서함입니다.
- **채널별 파일 위치**: Standard channel 파일은 팀 사이트의 SharePoint에 저장되고, Private channel은 별도의 SharePoint 사이트를 가집니다(Shared channel도 채널별 사이트).
- **공유 링크 네 가지**: Anyone, People in your organization, People with existing access, Specific people입니다.
- **외부 공유 계층**: 테넌트 > 사이트 > 링크 순서로, 위 단계가 아래 단계의 상한입니다.

</details>

### 7. 영상·자료 (한글 우선)

- 한글: 확인 불가(시도: 유튜브 검색, 사유: SharePoint·Teams 관리를 다룬 한글 영상을 찾지 못함). Microsoft Learn(한국어)의 Teams와 SharePoint 관리 문서를 먼저 보세요.
- 영문 보완: 확인 불가. SharePoint·Teams 구조를 다룬 영어 영상도 내용까지 확인한 것이 없습니다(시도: 후보 풀코스 영상의 자막 확인, 사유: 힌디어 강의이고 SharePoint·Teams 내용이 자막에 없어 제외).
