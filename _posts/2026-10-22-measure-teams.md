---
title: "[M365·Azure] 실측 Teams: 정책, 게스트·외부 액세스, 회의 기본값 (전체 기록)"
date: 2026-10-22 11:30:00 +0900
categories: [m365]
phase: 운영 설정 실측
seq: 3
tags: [M365·Azure, 실측, Teams, 게스트, 외부 액세스, 회의 정책, 전체 기록]
excerpt: "Teams 기본값을 읽기만 해서 판독하니 외부 도메인 모두 허용, 타사 앱 전부 허용, 회의 로비 우회 등 위험이 기본값에서 나왔습니다"
---

Teams를 기본값 그대로 두면 외부와 어디까지 열려 있을까요? 정책과 외부, 게스트, 회의 기본값을 읽기만 해서 판독하니 대부분 서비스 기본값 그대로였고, 외부 도메인 모두 허용, 타사 앱 전부 허용, 회의 로비 우회 같은 위험이 그 기본값에서 나왔습니다.

## 요약

- 사용자 정의 정책이 없어 Global 한 곳을 바꾸면 곧 전사 변경임
- 외부 접점은 Teams 안팎에 겹겹이 있어 Entra와 SharePoint 설정까지 함께 봐야 함
- 사용자별 정책 할당과 B2B direct connect 값은 확인 불가

측정은 2026-10-22(목)부터 2026-10-23(금)까지 했고 **모든 측정은 읽기 전용**입니다. 정책 편집 화면은 열어 읽기만 했고 저장이나 적용은 누르지 않았습니다. 방법과 판독 기준은 [측정 방법 글]({{ "/m365/measurement-method/" | relative_url }})에 있습니다.

> 근거: 조회는 화면에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 도메인과 계정은 게시하지 않았습니다. "개선 방안"은 권고이며 이번에 실행하지 않았습니다.

---

## 전체 기록

### 1. 정책 직접 할당 구조

<details markdown="1">
<summary>자세히 보기 (그림 2장)</summary>

- **GUI 경로**: Teams 관리 센터 > 팀 정책 / 메시징 정책 / 앱 설정 정책 / 업데이트 정책 / 이벤트 정책

각 정책 유형에 사용자 정의 정책이 없고 Global만 있었습니다(조회). 앱 설정 정책에는 기본 제공 FirstLineWorker가 하나 더 있어 2개입니다. 부서별 차등은 없습니다.

Global 메시징 정책은 열어서 값을 읽었습니다(읽기만 하고 저장하지 않음).

- 보낸 메시지 삭제 On, 채팅 삭제 On, 보낸 메시지 편집 On, 읽음 확인 "사용자가 제어"
- 소유자의 메시지 삭제 Off, 봇 메시지 삭제 Off, 사용자 지정 이모티콘 업로드 On·삭제 Off, 채팅 On
- 화면 아래쪽 항목(Giphy 등급, 음성 메시지 등)은 목록을 모두 옮겨 적지 않았습니다.

사용자가 자기 메시지를 편집하고 삭제할 수 있는 기본값 그대로입니다. 감사나 보존 요구가 있다면 이 값이 기준과 맞는지 따져 봐야 합니다.

참고로 팀 관리에는 Team이 8개(공개 6, 비공개 2) 있었고, 만료일 열은 전부 "-"였습니다.

개선 방안(미실행)은 부서나 역할별 사용자 정의 정책을 만들어 그룹에 할당하는 것입니다. 그룹 정책 할당은 사용자 직접 할당과 우선순위 규칙이 있으므로 설계한 뒤 적용합니다.

근거: [Teams 정책 개요](https://learn.microsoft.com/microsoftteams/teams-policies), 설정 기본값 표 [Teams settings and policies reference](https://learn.microsoft.com/microsoftteams/settings-policies-reference) (앞의 URL은 재검증하지 않음, 뒤의 표는 확인함)

![Teams 정책 화면]({{ "/assets/images/2026/10/m08-1-teams-policies.png" | relative_url }})
*그림 1. Teams 관리 센터 > 팀 > Teams 정책. 요약에 기본 정책 1, 사용자 정의 정책 0이고 목록에 "Global (Org-wide default)" 하나만 있습니다.*

![Teams Global 메시징 정책 상세]({{ "/assets/images/2026/10/m12-messaging-policy.png" | relative_url }})
*그림 2. Teams 관리 센터 > 메시징 정책 > Global(Org-wide default) 상세. 저장 버튼은 누르지 않고 취소로 나왔습니다.*

</details>

### 2. 조직 전체 앱 설정

타사 앱은 "All third-party apps available", 사용자 지정 앱 설치 켜짐, Microsoft 앱 켜짐이었습니다. 승인 대기 0건, 요청 0건입니다(조회).

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>


앱 허용 목록 통제가 없고 사용자가 사용자 지정 앱을 설치할 수 있으니, 데이터 접근 권한을 가진 앱이 관리자 모르게 늘어날 수 있습니다. 앱 승인 흐름을 쓰려면 먼저 허용 범위를 줄이는 결정이 필요합니다.

개선 방안(미실행)으로는 필요한 앱만 허용 목록으로 두고 나머지는 차단하며, 사용자 지정 앱 설치는 필요한 그룹에만 허용합니다. 앱 동의는 Entra 쪽 동의 정책과 함께 설계합니다([Identity 실측 글]({{ "/m365/measure-identity/" | relative_url }}) 참고).

근거: [Teams 앱 관리 개요](https://learn.microsoft.com/microsoftteams/manage-apps)

![조직 전체 앱 설정]({{ "/assets/images/2026/10/m08-2-orgwide-apps.png" | relative_url }})
*그림 3. Teams 관리 센터 > Teams 앱 > 앱 관리 > 조직 전체 앱 설정. 타사 앱은 "All third-party apps available", 사용자 지정 앱 설치와 미리보기 상호작용이 모두 On입니다. 뒤 화면에는 승인 대기 제출·업데이트 앱 0건이 보입니다(값만 읽고 저장은 누르지 않음).*

</details>

### 3. 게스트 액세스

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>

- **GUI 경로**: Teams 관리 센터 > 팀 > 게스트 액세스 (값만 읽고 저장이나 취소는 누르지 않음)

![Teams 관리 센터 게스트 액세스 화면. Guest access가 Service default: On으로 표시됨]({{ "/assets/images/2026/10/teams-guest-access.png" | relative_url }})
*그림 4. 빨간 상자: Guest access = Service default: On (서비스 기본값 그대로)*

서비스 기본값 켜짐, 화상(게스트 화상회의) 켜짐, 화면 공유 Entire screen, 외부 참가자 제어 꺼짐이었습니다(조회).

기본값 그대로라 위험으로 판독했지만, Guest 사용자가 0명이라 즉시 노출은 없습니다.

개선 방안(미실행): 게스트 기능을 쓰지 않는다면 끄고, 쓴다면 화면 공유를 "단일 앱"으로 줄입니다. Entra 외부 협업 설정과 SharePoint 공유 설정은 서로 다른 층이라 한 곳만 좁혀서는 충분하지 않다는 점을 아래 설계 문서가 설명합니다. 어느 쪽이 우선하는지의 세부 규칙은 원문으로 확인하지 못해 확인 불가입니다(아래 목록).

근거: [Teams 게스트 액세스](https://learn.microsoft.com/microsoftteams/guest-access), [Teams·SharePoint 보안 액세스 설계](https://learn.microsoft.com/entra/architecture/9-secure-access-teams-sharepoint)

</details>

### 4. 외부 액세스(페더레이션)

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>

- **GUI 경로**: Teams 관리 센터 > 사용자 > 외부 액세스

외부 도메인 관리는 켜져 있지만 "모든 외부 도메인 허용"이고, 관리되지 않는 Microsoft 계정과의 채팅과 회의도 켜져 있었습니다(조회).

게스트 액세스와 헷갈리기 쉬운데, 외부 액세스는 상대 조직 사용자와 **채팅·통화**를 하는 기능이고 게스트 액세스는 상대를 **팀 멤버로 초대**하는 기능입니다. 둘은 별개 설정입니다(문서).

개선 방안(미실행): 허용 도메인 목록 방식으로 바꾸고, 관리되지 않는 계정과의 통신은 필요할 때만 허용합니다. 신뢰할 조직과의 회의 참여는 신뢰할 수 있는 조직 설정으로 따로 다룹니다.

근거: [외부 조직 사용자와 통신](https://learn.microsoft.com/microsoftteams/communicate-with-users-from-other-organizations), [신뢰할 조직과 외부 회의·채팅](https://learn.microsoft.com/microsoftteams/trusted-organizations-external-meetings-chat), [통합 외부 협업 설정](https://learn.microsoft.com/microsoftteams/unified-external-collab-settings-management-experience)

![Teams 외부 액세스 설정]({{ "/assets/images/2026/10/m08-4-external-access.png" | relative_url }})
*그림 5. Teams 관리 센터 > 외부 협업 > 외부 액세스. "Allow all external domains"가 선택되어 있고, 관리되지 않는 Microsoft 계정과의 채팅·회의 옵션이 On입니다(값만 읽고 저장은 누르지 않음).*

</details>

### 5. 회의 정책(Global)과 로비

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>

- **GUI 경로**: Teams 관리 센터 > 회의 > 회의 정책 > Global

읽은 값(조회):

- 녹화 켜짐, 녹화 자동 만료 켜짐(120일), 참가자 동의(녹화·기록 알림) 꺼짐
- 로비 우회 = 내 조직과 게스트, 승인 = 주최자, 공동 주최자, 발표자
- 외부 회의 참여("People can join external meetings hosted by" 설정) = Anyone(문서 기본값과 같음)

로비는 위험, 나머지는 주의로 판독했습니다. 값은 문서의 기본값 표와 일치합니다. 로비 우회 대상에 게스트가 들어 있으니, 게스트가 생기는 순간 회의 보안에 영향을 줍니다.

개선 방안(미실행):

- 민감한 회의는 별도 정책을 만들어 그룹에 할당합니다.
- "로비를 우회할 수 있는 사람"을 "주최자 및 공동 주최자만"(OrganizerOnly) 또는 "초대된 사용자"(InvitedUsers)로 둡니다. "모든 사용자(Everyone)"는 오히려 가장 느슨한 값입니다.
- 녹화 보존은 법적, 업무 기준에 맞춰 일수를 정합니다.

근거: [로비 우회 설정](https://learn.microsoft.com/microsoftteams/who-can-bypass-meeting-lobby), [회의 정책 개요](https://learn.microsoft.com/microsoftteams/meeting-policies-overview), [설정·정책 기본값 표](https://learn.microsoft.com/microsoftteams/settings-policies-reference)

![회의 정책의 로비 설정]({{ "/assets/images/2026/10/m08-5-meeting-lobby.png" | relative_url }})
*그림 6. Teams 관리 센터 > 회의 > 회의 정책 > Global의 로비 영역. "Who can bypass the lobby"가 People in my org and guests, "Who can admit from the lobby"가 Organizers, co-organizers, and presenters, "People can join external meetings hosted by"가 Anyone입니다(값만 읽고 저장은 누르지 않음).*

</details>

### 6. 공유 채널

Global 팀 정책에서 공유 채널 생성, 외부 초대, 참여가 모두 켜져 있고 비공개 팀 검색은 꺼져 있었습니다. 공유 채널용 사용자 정의 정책은 0입니다(조회).

<details markdown="1">
<summary>자세히 보기</summary>


공유 채널은 팀 멤버가 아닌 사람(다른 조직 포함)을 **채널 단위로** 초대할 수 있고, 파일은 별도 사이트에 저장됩니다. 그런데 다른 조직 사용자가 공유 채널에 들어오려면 Entra의 B2B direct connect(인바운드·아웃바운드)가 필요합니다. 이 설정은 양방향 모두 기본이 차단이고, 양쪽 테넌트가 모두 설정해야 동작합니다(문서).

그래서 기본값에서는 팀 정책이 켜져 있어도 외부 조직 사용자가 바로 들어오지 못합니다. 이 테넌트의 B2B direct connect 값은 확인 불가입니다(아래 목록).

개선 방안(미실행): 외부 초대는 필요한 팀 정책으로 한정합니다. 공유 채널을 실제로 쓸 때 필요한 조직에 대해서만 인바운드와 아웃바운드를 열고 나머지는 기본(차단)으로 둡니다.

근거: [공유 채널 개요](https://learn.microsoft.com/microsoftteams/platform/build-apps-for-shared-private-channels), [채널 종류](https://learn.microsoft.com/microsoftteams/teams-channels-overview)

</details>

### 7. 이벤트 정책

웨비나와 타운홀이 켜져 있고(대상 Everyone), 등록 켜짐, 녹화 유형 Public이라(조회) 외부 청중 대상 행사를 열 수 있습니다. 대상을 "특정 사용자와 그룹" 또는 "조직 내부"로 줄이는 선택지가 있습니다.

근거: [Teams 이벤트 계획](https://learn.microsoft.com/microsoftteams/plan-events)

### 8. 업데이트 정책

Global 정책에서 미리보기가 "Current Channel (Preview) 사용자에게 켜짐"이고, 새 Teams 클라이언트는 Microsoft가 제어합니다(조회). 변경 영향을 미리 보려면 미리보기 대상 그룹을 따로 두는 편이 안전합니다.

### 9. 읽어 보고 정리한 운영 기준

서비스 기본값 그대로인 곳은 게스트, 외부 액세스, 로비, 이벤트였습니다. 외부 접점은 Teams 안(게스트, 외부 액세스, 공유 채널)과 밖(Entra 외부 협업, SharePoint 공유)에 있습니다. 비어 있는 보고서는 측정 불가로 적었습니다.

### 10. 작업 중 막힌 곳

- Teams PowerShell 연결이 로그인 방식(AADSTS530035)에 막혀 사용자별 정책 할당은 확인 불가로 남겼습니다. [AADSTS530035 트러블슈팅]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})
- 사용 현황 보고서 "데이터 없음": 시간을 두고 다시 조회합니다. [사용 현황 보고서 트러블슈팅]({{ "/m365/troubleshooting/usage-report-no-data/" | relative_url }})

### 11. 끝내 확인하지 못한 것

보고서 이름 숨김(익명화 ON)이 켜져 있어 보고서가 나와도 팀 이름은 해시로 표시됩니다(측정 범위 밖이라 바꾸지 않음).

<details markdown="1">
<summary>확인 불가 항목 펼쳐 보기 (7건)</summary>

- **사용자별 정책 직접 할당 수**
    - 시도 방법: Get-CsOnlineUser 조회
    - 막힌 이유: Teams PowerShell 로그인 방식을 확인하지 못해 실행하지 못함(Exchange 연결은 보안 기본값 때문에 AADSTS530035로 막힘)
    - 다음 방법: 내 PC에서 브라우저 로그인 후 조회
- **그룹 정책 할당(업데이트 정책 외)**
    - 시도 방법: 업데이트 정책의 그룹 할당만 열어 0건 확인
    - 막힌 이유: 다른 정책 유형은 읽지 않음
    - 다음 방법: 정책 유형별 그룹 할당 화면을 열어 읽기
- **비활성 Team 비율**
    - 시도 방법: M365 관리 센터 > 사용 현황 > Teams 보고서
    - 막힌 이유: "이 보고서에 대한 데이터가 없습니다"(데이터 없음). 원인 후보는 보고서 생성 지연(문서 기준 통상 24~72시간), 샌드박스 활동 부족, 보고서 읽기 권한
    - 다음 방법: 활동 발생 뒤 72시간쯤 지나 재조회, 또는 Teams 관리 센터 팀 관리의 최종 활동 열 확인
- **소유자 없는 Team**
    - 시도 방법: 목록과 활성 팀 및 그룹 화면 확인
    - 막힌 이유: 소유자 수 열이 없음
    - 다음 방법: 팀별 상세 확인 또는 Graph 조회
- **익명 사용자 회의 참가**
    - 시도 방법: 해당 설정을 읽지 않음(문서 기본값 On만 확인)
    - 막힌 이유: 이번 측정 항목에서 빠졌음
    - 다음 방법: 해당 설정 화면을 열어 읽기
- **B2B direct connect(인바운드·아웃바운드) 값**
    - 시도 방법: 이 항목을 따로 읽지 않음
    - 막힌 이유: 이번 측정 항목에서 빠졌음
    - 다음 방법: Entra 테넌트 간 액세스 설정에서 읽기
- **Entra, SharePoint, Teams 설정의 우선 규칙 세부**
    - 시도 방법: 설계 문서 링크만 확인
    - 막힌 이유: 해당 문서를 원문으로 다시 확인하지 못함
    - 다음 방법: 설계 문서 원문에서 우선 규칙 확인

</details>

### 12. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- **문서(정책 개요와 기본값 표)**: [Teams 정책 개요](https://learn.microsoft.com/microsoftteams/teams-policies) (재검증하지 않음), [Teams settings and policies reference](https://learn.microsoft.com/microsoftteams/settings-policies-reference)
- **문서(앱 관리)**: [Teams 앱 관리 개요](https://learn.microsoft.com/microsoftteams/manage-apps)
- **문서(게스트 액세스와 외부 접근 설계)**: [Teams 게스트 액세스](https://learn.microsoft.com/microsoftteams/guest-access), [Teams·SharePoint 보안 액세스 설계](https://learn.microsoft.com/entra/architecture/9-secure-access-teams-sharepoint)
- **문서(외부 액세스)**: [외부 조직 사용자와 통신](https://learn.microsoft.com/microsoftteams/communicate-with-users-from-other-organizations), [신뢰할 조직과 외부 회의·채팅](https://learn.microsoft.com/microsoftteams/trusted-organizations-external-meetings-chat), [통합 외부 협업 설정](https://learn.microsoft.com/microsoftteams/unified-external-collab-settings-management-experience)
- **문서(공유 채널, 채널 종류)**: [공유 채널 개요](https://learn.microsoft.com/microsoftteams/platform/build-apps-for-shared-private-channels), [채널 종류](https://learn.microsoft.com/microsoftteams/teams-channels-overview)
- **문서(이벤트, 회의 정책)**: [Teams 이벤트 계획](https://learn.microsoft.com/microsoftteams/plan-events), [로비 우회 설정](https://learn.microsoft.com/microsoftteams/who-can-bypass-meeting-lobby), [회의 정책 개요](https://learn.microsoft.com/microsoftteams/meeting-policies-overview)
- **조회(정책 현황, 외부·게스트·회의 값)**: 위 각 절의 GUI 경로와 그림

</details>
