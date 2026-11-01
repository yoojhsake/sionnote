---
title: "[Troubleshooting] 루트 IAM에 경고가 뜨고, Elevate를 끈 뒤 루트 역할 목록이 열리지 않음"
date: 2026-10-23 22:40:00 +0900
categories: [m365, troubleshooting]
area: 로그인·권한
seq: 4
tags: [Azure, Elevate access, RBAC, 루트 IAM, denyAssignments, 감사 로그, 전체 기록]
excerpt: "Elevate를 끄자 루트 역할 목록이 열리지 않았습니다. 토글·감사 로그·제거 직후 0건 조회로 제거를 대신 확인했습니다."
---

Elevate access를 켠 루트 IAM 화면에는 `denyAssignments/read` 경고가 뜨고, 끈 뒤에는 역할 목록이 아예 열리지 않았습니다. 그래서 할당 제거를 화면 대신 토글 "아니요", 감사 로그 "removed", PowerShell 제거 직후 0건 조회로 확인했습니다.

## 요약

- 끈 뒤 루트 역할 목록이 안 열리는 것은 루트 범위 권한이 사라져서임
- 제거 여부는 토글, 감사 로그, 제거 직후 0건 조회를 겹쳐 확인하면 됨
- 켠 화면에 뜬 denyAssignments 경고의 원인은 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 구독 ID도 게시하지 않았습니다. Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.

---

## 전체 기록

### 1. 증상

- 사례 1(켠 상태): Tenant Root Group > 액세스 제어(IAM)에 User Access Administrator가 범위 "루트 (상속됨)"으로 보였고 `Get-AzRoleAssignment -Scope '/'`도 1건이었지만, `denyAssignments/read` 관련 경고가 함께 떴습니다.
- 사례 2(끈 상태): 관리 그룹 화면은 "권한 없음" 안내로 돌아왔고 루트 IAM 역할 목록은 열리지 않았습니다.

![Elevate를 끈 뒤의 관리 그룹 화면]({{ "/assets/images/2026/10/m12-2-elevate-off-banner.png" | relative_url }})
*그림 2. Elevate를 끈 뒤(10/23 22:10)의 관리 그룹 화면(GUI). "디렉터리 관리자로 등록되어 있지만, 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다"라는 안내가 나오고, Tenant Root Group 이름이 더 이상 파란 링크가 아니다. 구독은 구독 자체에 대한 권한으로 계속 보입니다. 구독 이름, ID, 테넌트 ID는 가렸습니다.*

### 2. 원인 및 분석

문서는 Elevate가 루트 `/`에 User Access Administrator를 주고 토글을 끄면 제거한다고 설명합니다([Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)). 그래서 사례 2는 정상이고, 제거는 다음으로 대신 확인했습니다.

- 토글: "아니요", 새로 불러온 화면에서 저장 버튼 비활성
- 관리 그룹: "권한 없음" 안내 복귀(끈 직후 09:51, 16시경, 22:10)
- 감사 로그: 켬·끔 시각 모두 기록, 제거는 "The role assignment of User Access Administrator has been removed from the user"
- PowerShell: 4회차, 5회차 제거 직후 `Get-AzRoleAssignment` 0건

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 3장)</summary>

#### 켠 상태의 루트 IAM

![Elevate 후. 루트 IAM 역할 할당 탭에 User Access Administrator가 범위 / 로 보이고, PowerShell도 같은 값]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 1. Elevate 후 상태(위: Entra 토글 "예" 22:02 / 가운데: Tenant Root Group > 액세스 제어(IAM)에서 User Access Administrator가 범위 "루트 (상속됨)"으로 보임, 10/24 00:56 / 아래: PowerShell `Get-AzRoleAssignment -Scope '/'`로 같은 값 확인, 00:56). 계정 이름은 가렸습니다. 토글은 22:02(4회차)에, 루트 IAM은 22:28에 켠 5회차 상태에서 찍어 시점이 다릅니다.*

#### 처음에 짚은 것

- 켠 상태에서 무엇이 생겼나: 루트(`/`) 범위의 **User Access Administrator** 1건(Owner, Contributor가 아님). 다른 사용자에게 Azure 역할을 줄 수 있는 역할입니다.
- 경고는 역할이 없어서인가: 역할 목록은 읽혔고 PowerShell도 1건을 돌려줬습니다. 경고가 뜬 것과 목록이 읽힌 것이 함께 있습니다.
- 끈 뒤 목록이 안 열리는 것은 이상한가: 끄면 루트 범위 권한이 사라지므로 권한 없음 안내로 돌아오는 것이 정상적인 방향입니다(문서는 토글을 끄면 제거된다고 설명).

#### 경고 원인 확인

원인은 **확인 불가**입니다. 부여된 역할(User Access Administrator)에 `denyAssignments/read` 읽기 권한이 포함되지 않기 때문일 수 있다는 추정만 있습니다.

- 시도 방법: 켠 상태의 루트 IAM 화면에서 경고 확인, 목록 조회
- 막힌 이유: 역할 정의를 바꾸거나 다른 역할을 받아 확인하는 것은 권한 변경이라 하지 않음
- 다음 방법: 운영 환경에서 변경 권한이 있을 때 역할 정의 대조

#### 끈 뒤 루트 역할 목록 읽기

- 끈 뒤 루트 IAM 역할 목록을 GUI로 열기: 목록 자체가 열리지 않음(권한 없음)
- 1~3회차(10/22 09:57~11:02:59, 10/23 09:46:43~09:50:23, 09:56:36~16:01:10)에 PowerShell로 루트 목록 읽기: 하지 않음
    - 이 세 번의 "제거됨" 근거는 감사 로그와 "권한 없음" 안내 복귀입니다.
- 4회차(22:02:46~22:08:48): 토글 끄기가 GUI로 실패해 PowerShell로 제거
    - `Get-AzRoleAssignment`로 제거 전 1건 → 제거 후 **0건**([끄지 못한 과정]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}))
- 5회차(22:28:48~10/24 00:58:50): PowerShell로 제거
    - 제거 뒤 같은 조회는 0건

![원복 후. Entra 속성 토글 아니요와 감사 로그 제거 기록]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 3. 원복 후(위: Entra 속성 토글 = "아니요", 새로 불러온 화면, 22:09 / 아래: 감사 로그 조회에서 제거 기록 "The role assignment of User Access Administrator has been removed from the user"가 보임, 10/24 00:5x 조회 화면). 계정 이름은 가렸습니다.*

![PowerShell로 지운 항목의 세부 정보. 사용자 에이전트에 Azure PowerShell이 보임]({{ "/assets/images/2026/10/m12-3c-audit-detail-ps.png" | relative_url }})
*그림 4. 22:08:48 "removed" 항목의 세부 정보(GUI). 범주와 상태는 같고, 사용자 에이전트에 `cloud-shell … AzurePowershell`이 찍혀 있어 이 제거가 화면 토글이 아니라 Cloud Shell의 PowerShell 호출이었음을 로그로도 확인할 수 있습니다. 상관관계 ID는 가렸고, 아래쪽 개체, 세션, IP, 계정 항목은 게시하지 않았습니다.*

</details>

### 3. 결론

Elevate 끔 → 루트 범위 권한 제거 → 루트 IAM 목록 안 열림(정상) → 토글·감사 로그·0건 조회로 확인

- 사례 1 경고 원인: 확인 불가. 역할에 `denyAssignments/read`가 없어서라는 추정만 있습니다(시도: 켠 상태에서 경고와 목록 조회, 사유: 역할 정의 변경은 권한 변경이라 하지 않음, 다음 방법: 변경 권한이 있을 때 역할 정의 대조).
- 끈 뒤 루트 역할 목록 직접 확인: 확인 불가(시도: 목록 열기, 사유: 권한 없음, 다음 방법: 대체 근거 사용).

### 4. 권고방안

1. Elevate는 쓰고 나면 끄고, 켬·끔 시각을 기록합니다.
2. 조치 후 확인: 끈 뒤 PowerShell 조회와 감사 로그로 한 번 더 읽고, "제거됨"은 한 가지 근거로 단정하지 않습니다.
3. 역할 정의를 바꿔 확인하는 일은 권한 변경이라 하지 않습니다.

관련 글: [관리 그룹 설정이 403: Elevate access와 토큰]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}) · [Elevate를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}) · [Azure 구조: 계층, 리소스 그룹, Elevate access 전·후]({{ "/m365/d4-azure-structure/" | relative_url }})

### 근거 자료

> 이 글의 PowerShell 원문은 일부를 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- 문서: Elevate access. 루트 `/`에서 User Access Administrator, 토글 끄기로 제거, 배너
    - 출처: [Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)
- 조회: 켠 상태 루트 IAM의 User Access Administrator 1건, PowerShell 1건, 끈 뒤 화면과 토글, 감사 로그, 제거 직후 0건
    - 출처: Azure 포털, Entra, Cloud Shell
- 확인 불가: denyAssignments 경고 원인, 끈 뒤 루트 역할 목록의 직접 확인(시도, 사유, 다음 방법은 2절 확인 과정의 '경고 원인 확인', '끈 뒤 루트 역할 목록 읽기')
    - 출처: -

</details>
