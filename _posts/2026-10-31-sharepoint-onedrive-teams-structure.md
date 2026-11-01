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

- Teams의 Team 하나는 Microsoft 365 group, SharePoint 팀 사이트, Exchange 그룹 사서함이 묶인 것. 파일은 SharePoint와 OneDrive에 저장
- Standard channel 파일은 팀 사이트의 SharePoint에, 채팅 파일은 OneDrive에. Private channel과 Shared channel은 채널마다 별도의 SharePoint 사이트
- 사이트 권한은 Owners, Members, Visitors 그룹으로 부여. 라이브러리와 파일은 기본적으로 상위 권한을 상속하고, 고유 권한이 많을수록 관리가 어려움
- 외부 공유는 테넌트 설정이 사이트 설정의 상한. 사이트에서 허용해도 테넌트가 막으면 공유 안 됨
- 구성원은 그룹에서, 파일 권한은 SharePoint에서 봄. 데이터 보호(레이블·DLP)는 Microsoft Purview에서 관리

12주 학습 로드맵의 7주차입니다.
이전 글: [6주차 Exchange Online]({{ "/study/exchange-online-basics/" | relative_url }}) · 다음 글: [8주차 Intune]({{ "/study/intune-device-management/" | relative_url }}) · [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

SharePoint Online, Site(Team site·Communication site), Hub site, OneDrive for Business, Microsoft 365 group, Team, Channel(Standard·Private·Shared), Owners·Members·Visitors, Sharing link(Anyone·People in your organization·Specific people), External sharing, Guest access, Permission inheritance, Sensitivity label, Retention label, DLP(Data Loss Prevention), Microsoft Purview

### 2. 개념 설명

Team은 협업 구성요소가 묶인 패키지입니다. 구성원은 Microsoft 365 group이 관리하고, 파일은 팀 사이트에 저장됩니다.

- Standard channel의 파일은 팀 사이트의 SharePoint에, 채팅 파일은 OneDrive에 저장됩니다.
- Private channel은 별도의 SharePoint 사이트를 가집니다.
- Shared channel도 채널마다 자기 SharePoint 사이트를 가집니다(문서: [Teams와 SharePoint 통합 개요](https://learn.microsoft.com/sharepoint/teams-connected-sites#teams-connected-sites-and-channel-types)). Standard channel만 팀 사이트 하나를 함께 쓰고 채널별 폴더로 나뉩니다.
- 채널 유형별 저장 위치를 실제 테넌트에서 조회한 기록은 [Teams 저장 구조 실습]({{ "/m365/d3-teams-storage/" | relative_url }})에 있습니다.

SharePoint 사이트는 Owners, Members, Visitors 그룹으로 권한을 부여하고, 문서 라이브러리와 파일은 기본적으로 상위 권한을 상속(inheritance)합니다. 고유 권한(unique permissions)을 많이 만들수록 관리가 어려워집니다.

공유 링크는 Anyone(링크만 있으면 누구나), People in your organization, People with existing access, Specific people의 네 가지입니다. 외부 공유는 **테넌트 설정이 사이트 설정의 상한**이 되는 계층 구조입니다.

데이터 보호인 Sensitivity label(분류·암호화), Retention label과 retention policy(보존·삭제), DLP(유출 방지)는 Microsoft Purview에서 관리합니다. 관리 센터도 SharePoint admin center와 Teams admin center로 나뉘어 있어 따로 씁니다.

### 3. 온프레미스로 번역하면

| M365 | 온프레미스 |
|---|---|
| 팀 사이트 | 파일 서버의 부서 공유 폴더 |
| Owners·Members·Visitors | 폴더 ACL 그룹 |
| 공유 링크 | 임시 공유 URL |

다른 점은 "폴더 경로로 접근"에서 "링크와 사이트 구성원으로 접근"하는 모델로 바뀐다는 것입니다.

### 4. 실습 (GUI 우선)

1. SharePoint 관리 센터 > 사이트 > 활성 사이트에서 사이트 목록과 유형을 봅니다.
2. 정책(Policies) > 공유(Sharing)에서 테넌트 수준의 외부 공유 설정을 확인합니다. 설정은 바꾸지 않고 읽기만 합니다.
3. Teams 관리 센터(admin.teams.microsoft.com) > 팀 > 팀 관리에서 Team 하나를 열어 Owners, Members, 채널 유형을 확인합니다.
4. 같은 Team에 연결된 SharePoint 사이트를 찾아 두 곳의 구성원이 같은지 비교합니다.

### 5. 전문가처럼 말하기

> "Team은 Microsoft 365 group을 membership backbone으로 하고 SharePoint 팀 사이트와 그룹 사서함이 붙은 구조입니다. 그래서 구성원 관리는 그룹에서, 파일 권한은 SharePoint에서 봐야 합니다."
>
> "외부 공유는 테넌트 설정이 상한이라서, 사이트에서 허용해도 테넌트가 막으면 공유되지 않습니다."

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
- **외부 공유 계층**: 테넌트 > 사이트 > 링크 순서로, 위 단계가 아래 단계의 상한입니다. 사이트에서 허용해도 테넌트가 막으면 공유되지 않습니다.

</details>

### 7. 영상·자료 (한글 우선)

- 한글: 확인 불가(시도: 유튜브 검색, 사유: SharePoint·Teams 관리를 다룬 한글 영상을 찾지 못함). Microsoft Learn(한국어)의 Teams와 SharePoint 관리 문서를 먼저 읽으세요.
- 영문 보완: [Microsoft 365 Administrator Full Course 2026](https://www.youtube.com/watch?v=v0xa7SzeXjA)에서 SharePoint와 Teams 구간을 찾아 보세요(목차는 직접 확인하세요).
