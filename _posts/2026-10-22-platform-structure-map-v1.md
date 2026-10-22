---
title: "[M365 Readiness] 플랫폼 구조 지도 v1.0 — M365·Identity·Teams·Azure를 A3 한 장에 (전체 기록)"
date: 2026-10-22 18:30:00 +0900
categories: [m365]
tags: [Readiness, 구조 지도, M365, Entra, Teams, Azure, RBAC, 전체 기록]
excerpt: "실습으로 직접 확인한 값과 공식 문서를 근거로 네 영역의 구조를 A3 한 장에 정리한 지도와, 초안(v0.9)에서 바뀐 점·확인하지 못한 점의 기록"
---

D1~D4 실습과 읽기 전용 측정으로 확인한 값, 공식 문서를 근거로 **네 영역(M365, Identity, Teams, Azure)의 구조를 A3 한 장에 그린 지도**입니다. 지도의 각 칸에는 근거 표시를 붙였습니다.

> 근거 표기: **조회** = 이 테넌트에서 직접 확인 / **문서** = Microsoft Learn / **미확인** = 확인하지 못함. 테넌트 ID·구독 ID·도메인·계정은 지도와 글에 넣지 않았고, 주소의 도메인 자리는 `<테넌트>`로 적었습니다.

## 1. 지도

![M365, Identity, Teams, Azure 네 영역의 구조를 A3 한 장에 정리한 플랫폼 구조 지도 v1.0]({{ "/assets/images/2026/10/platform-map-v1.png" | relative_url }})
*그림 1. 플랫폼 구조 지도 v1.0 (클릭하면 원본 크기)*

- A3 PDF: [platform-map-v1.0.pdf]({{ "/assets/files/platform-map-v1.0.pdf" | relative_url }}) (한 장, 벡터라 확대해도 글자가 깨지지 않습니다)

## 2. 지도를 이렇게 그렸다

**목표**: 새로 합류한 운영자가 "이 테넌트의 어디에 무엇이 있고, 누가 무엇을 바꿀 수 있는가"를 한 장으로 이해하게 한다.

| 영역 | 지도에 담은 구조 | 직접 확인한 근거 |
|---|---|---|
| ① M365 | Tenant → 도메인, SKU → 서비스 플랜, 관리 센터별 용도 | SKU 구매 25 / 사용 20 / 남음 5, 서비스 플랜 12개 Success, Planner를 껐다 켜도 사용 수 20 유지([D1 글]({{ "/m365/readiness-d1-m365-structure/" | relative_url }})) |
| ② Identity | AD → Entra Connect/Cloud Sync → Entra ID, Source of authority, 그룹 기반 라이선스 흐름, Soft/Hard match | 클라우드 전용, 동적 그룹 규칙, 그룹 라이선스 할당은 M365 관리 센터에서만([D2 글]({{ "/m365/readiness-d2-identity-groups/" | relative_url }})) |
| ③ Teams | Team = M365 그룹 + SharePoint 사이트 + 그룹 사서간, 채널 유형별 파일 위치, 일정의 Exchange 의존 | Team 7→8, 세 채널의 실제 폴더 주소 패턴([D3 글]({{ "/m365/readiness-d3-teams-storage/" | relative_url }})) |
| ④ Azure | Tenant → 관리 그룹 → 구독 → 리소스 그룹 → 리소스, RBAC 상속, Entra 역할과 RBAC의 분리, Elevate access 전·후 | 구독 1, 리소스 그룹 1→3, Elevate 09:57 켬 / 11:02 끔, 루트 IAM 확인([D4 글]({{ "/m365/readiness-d4-azure-structure/" | relative_url }})) |

## 3. 영역별 설명

### ① M365 — "라이선스는 서비스 플랜의 묶음"
- Tenant와 도메인은 신원 쪽 이야기이고, 라이선스(SKU)는 그 위에서 사용자·그룹에 붙는 상품입니다. SKU 안에 서비스 플랜이 여러 개 들어 있고, **사용자별로 플랜을 끌 수 있지만 SKU 사용 수는 줄지 않습니다.**
- 관리 센터는 용도별로 나뉩니다. M365 관리 센터(사용자·청구·그룹 라이선스·메시지 센터·서비스 상태), Entra(사용자·그룹·역할·조건부 액세스), Teams, SharePoint, Purview, Azure Portal. **Exchange 관리 센터는 화면을 열지 않았고** PowerShell 연결도 로그인 차단으로 막혀 미확인입니다([트러블슈팅 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})).
- 관리 센터별 필요 역할(전역 관리자 외 세분 역할)은 이 테넌트에서 비교하지 못해 **미확인**으로 남겼습니다.

### ② Identity — "누가 원본인가"
- 온프레미스 AD가 있다면 Entra Connect Sync 또는 Cloud Sync로 Entra ID에 개체가 동기화되고, **동기화된 개체의 원본은 AD**입니다(문서). 이 테넌트는 Entra 개요에 "사용 안 함, 동기화 실행된 적 없음"으로 나오는 **클라우드 전용**이라 모든 개체의 원본이 Entra입니다(조회).
- Soft match와 Hard match는 동기화할 때 이미 존재하는 클라우드 계정과 같은 사람을 묶는 방식입니다. 이 테넌트에서는 실행할 수 없어 **문서 기준**으로만 그렸습니다.
- 그룹 기반 라이선스 흐름은 직접 해 본 값을 넣었습니다. 동적 그룹(규칙 `department -eq "Sales"`, 구성원 18) → 그룹에 라이선스 할당(**M365 관리 센터에서만** 가능, Entra의 그룹 라이선스 탭은 안내만 표시) → 구성원 반영. 시험 그룹에서 구성원이 0→1→0으로 바뀌었고, 사용자 쪽에 그룹 경로 라이선스가 추가되었는지 상세는 기록하지 못해 **미확인**입니다.

### ③ Teams — "Team은 세 가지가 묶인 것"
- Team은 M365 그룹(멤버·소유자) + SharePoint 사이트(파일) + 그룹 사서함(일정·메일)입니다. 일정은 Exchange에 의존합니다.
- 채널 유형별 실제 위치:

| 유형 | 실제 파일 위치 | 구분 |
|---|---|---|
| 표준 채널 | 팀 사이트 안 폴더 `…/sites/Practice-Team-01/Shared Documents/ch-standard` | 조회 |
| 비공개 채널 | **별도 사이트** `…/sites/Practice-Team-01-ch-private/Shared Documents` | 조회 |
| 공유 채널 | **별도 사이트** `…/sites/Practice-Team-01-ch-shared/Shared Documents` | 조회 |
| 1:1·그룹 채팅 파일 | 보낸 사람의 OneDrive | 문서, 이 테넌트 미확인 |
| 회의 녹화 | 채널 회의는 해당 채널 위치, 그 외는 진행자 OneDrive | 문서, 이 테넌트 미확인 |

- 비공개·공유 채널 업로드가 403으로 응답했는데 파일은 SharePoint에 있었던 점은 지도에는 적지 않고, 원인 **미확인**으로 D3 글에 남겼습니다.

### ④ Azure — "Tenant와 구독은 다른 상자"
- Tenant는 신원 경계, 구독은 요금·리소스 경계입니다. 구독은 정확히 하나의 테넌트를 신뢰합니다(문서). 지도에서는 Tenant와 구독을 **서로 다른 상자**로 그렸습니다.
- 관리 그룹은 Tenant Root Group 1개, 구독 1개(종량제, 지출 한도 Off), 리소스 그룹 1→3(실습 2개 추가).
- RBAC는 위쪽 범위의 역할이 아래로 상속됩니다. 같은 관리자 계정이 Entra에서는 **전역 관리자**, Azure에서는 **구독 Owner**이지만 전역 관리자라고 해서 루트 관리 그룹이 보이지는 않습니다(조회). 이 두 역할 체계가 따로라는 점이 지도의 핵심입니다.
- **Elevate access 전·후·원복**을 지도에 넣었습니다.

| 시점 | 읽은 값(조회) |
|---|---|
| 전 (09:52) | 토글 "아니요", 관리 그룹 화면에 "루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내, 관리 그룹 설정 읽기 HTTP 403(10/19) |
| 후 (09:57 켬, 계정 소유자가 직접) | 루트(`/`)에 User Access Administrator, 루트 IAM에 "1 사용자가 상승된 액세스" 배너, PowerShell ROOT 줄 확인 |
| 원복 (11:02 끔, 11:3x 확인) | 토글·안내 문구는 전과 같음. 루트 역할 목록 재조회는 **미확인** |

## 4. 초안(v0.9)에서 바뀐 점

| 항목 | v0.9 | v1.0 |
|---|---|---|
| Team 수 | 6개 | 7→8(조회로 정정) |
| 채널 파일 위치 | 실제 주소 미확인 | 세 채널의 실제 주소 패턴 |
| Elevate access 후 | "시연 때 채움" | 전·후·원복 값 |
| 그룹 라이선스 흐름 | 실습 결과 미확인 | 시험 그룹 결과 반영(일부 미확인) |
| 식별 정보 | 테넌트 ID 일부·도메인 표시 | 모두 가림 |
| 표기 | "초안" | 정식 v1.0 |

## 5. 이 지도의 한계

- 동기화(Entra Connect/Cloud Sync)와 Soft/Hard match는 이 테넌트에 없어 **문서 기준**으로만 그렸습니다.
- 1:1 채팅 파일, 회의 녹화의 실제 저장 위치는 이 테넌트에서 확인하지 않았습니다.
- Elevate access 원복 후 루트 역할 목록과 그룹 라이선스가 사용자에게 붙은 상세 상태는 미확인입니다.
- 이 지도는 기술 구조도이며, 설정의 안전·위험 판독은 [실측 글]({{ "/m365/readiness-measurement-method/" | relative_url }})에 따로 있습니다.

## 6. 근거 자료

| 영역 | 내용 | 출처 |
|---|---|---|
| 라이선스 | 사용자·그룹에 라이선스 할당 | [Assign licenses to users](https://learn.microsoft.com/microsoft-365/admin/manage/assign-licenses-to-users), [Manage group licenses](https://learn.microsoft.com/microsoft-365/admin/manage/manage-group-licenses) |
| 동적 그룹 | 동적 구성원 규칙 | [Dynamic membership rules](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership) |
| Tenant–구독 | 구독과 디렉터리의 관계 | [구독과 디렉터리 연결](https://learn.microsoft.com/entra/fundamentals/how-subscriptions-associated-directory) |
| Azure 계층 | 관리 그룹과 범위 | [Management groups](https://learn.microsoft.com/azure/governance/management-groups/overview), [Azure Resource Manager overview](https://learn.microsoft.com/azure/azure-resource-manager/management/overview) |
| 역할 체계 | Entra 역할과 Azure RBAC의 분리 | [RBAC and directory admin roles](https://learn.microsoft.com/azure/role-based-access-control/rbac-and-directory-admin-roles), [Entra 역할 개념](https://learn.microsoft.com/entra/identity/role-based-access-control/concept-understand-roles) |
| Elevate access | 루트에서 User Access Administrator, 끄면 제거 | [Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| Teams 저장 | 채널 유형별 사이트 | [Teams connected sites](https://learn.microsoft.com/sharepoint/teams-connected-sites), [Teams와 M365 그룹](https://learn.microsoft.com/microsoftteams/office-365-groups), [Teams 채널 개요](https://learn.microsoft.com/microsoftteams/teams-channels-overview), [공유·비공개 채널](https://learn.microsoft.com/microsoftteams/platform/build-apps-for-shared-private-channels) |
| Soft/Hard match | 기존 테넌트에 Entra Connect 설치 | [Install in existing tenant](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-install-existing-tenant) |
| 조회 | 모든 "조회" 표시 값 | D1~D4 글과 실측 글의 화면·PowerShell 기록 |
