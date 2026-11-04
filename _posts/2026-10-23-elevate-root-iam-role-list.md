---
title: "[Troubleshooting] 루트 IAM에 경고가 뜨고, Elevate를 끈 뒤 루트 역할 목록이 열리지 않음"
date: 2026-10-23 22:40:00 +0900
categories: [m365, troubleshooting]
area: 로그인·권한
seq: 4
tags: [Azure, Elevate access, RBAC, 루트 IAM, denyAssignments, 감사 로그, 전체 기록]
excerpt: "Elevate를 끄자 루트 역할 목록이 열리지 않았습니다. 토글·감사 로그·제거 직후 0건 조회로 제거를 대신 확인했습니다."
---

Elevate access를 켠 루트 IAM 화면에는 `denyAssignments/read` 경고가 떴고(2026-11-04에 다시 재현해 캡처, 그림 6), 끈 뒤에는 역할 목록이 아예 열리지 않았습니다. 그래서 할당 제거를 화면 대신 토글 "아니요", 감사 로그 "removed", PowerShell 제거 직후 0건 조회(4회차, 캡처 없음)로 확인했습니다.

## 요약

- 끈 뒤 루트 역할 목록이 안 열리는 것은 루트 범위 권한이 사라져서임
- 제거 여부는 토글, 감사 로그, 제거 직후 0건 조회를 겹쳐 확인하면 됨
- 켠 화면에 뜬 denyAssignments 경고는 문서의 역할 정의(`*/read` 포함)와 맞지 않아 권한 반영 지연 때문일 가능성이 있지만(추정), 켠 지 약 1~2분 시점에서만 확인했고 오래 두고 다시 보는 시험은 하지 않았음

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 구독 ID도 게시하지 않았습니다. Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.

---

## 전체 기록

### 1. 증상

- 사례 1(켠 상태): Tenant Root Group > 액세스 제어(IAM)에 User Access Administrator가 범위 "루트 (상속됨)"으로 보였고 `Get-AzRoleAssignment -Scope '/'`도 1건이었지만, `denyAssignments/read` 관련 경고가 함께 떴습니다.
- 사례 2(끈 상태): 관리 그룹 화면은 "권한 없음" 안내로 돌아왔고 루트 IAM 역할 목록은 열리지 않았습니다.

![Elevate를 끈 뒤의 관리 그룹 화면]({{ "/assets/images/2026/10/m12-2-elevate-off-banner.png" | relative_url }})
*그림 2. Elevate를 끈 뒤(10/23 22:10)의 관리 그룹 화면(GUI). "디렉터리 관리자로 등록되어 있지만, 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다"라는 안내가 나오고, Tenant Root Group 이름이 더 이상 파란 링크가 아닙니다. 구독은 구독 자체에 대한 권한으로 계속 보입니다. 구독 이름, ID, 테넌트 ID는 가렸습니다.*

### 2. 원인 및 분석

문서는 Elevate가 루트 `/`에 User Access Administrator를 주고 토글을 끄면 제거한다고 설명합니다([Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)). 그래서 사례 2는 정상이고, 제거는 다음으로 대신 확인했습니다.

- 토글: "아니요", 새로 불러온 화면에서 저장 버튼 비활성
- 관리 그룹: "권한 없음" 안내 복귀(끈 직후 09:51, 16시경, 22:10)
- 감사 로그: 켬·끔 시각 모두 기록, 제거는 "The role assignment of User Access Administrator has been removed from the user"
- PowerShell: 4회차 제거 직후 `Get-AzRoleAssignment` 0건(캡처 없음, 당시 출력 원문 복구 못함). 5회차는 감사 로그 "removed"가 근거

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 6장)</summary>

#### 켠 상태의 루트 IAM

![Elevate 후. 루트 IAM 역할 할당 탭에 User Access Administrator가 범위 / 로 보이고, PowerShell도 같은 값]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 1. Elevate 후 상태(이 10/23 캡처에는 denyAssignments 경고가 없습니다. 경고 화면은 11-04에 다시 재현해 그림 6에 실었습니다. 위: Entra 토글 "예" 22:02 / 가운데: Tenant Root Group > 액세스 제어(IAM)에서 User Access Administrator가 범위 "루트 (상속됨)"으로 보임, 10/24 00:56 / 아래: PowerShell `Get-AzRoleAssignment -Scope '/'`로 같은 값 확인, 00:56). 계정 이름은 가렸습니다. 토글은 22:02(4회차)에, 루트 IAM은 22:28에 켠 5회차 상태에서 찍어 시점이 다릅니다.*

#### 처음에 짚은 것

- 켠 상태에서 무엇이 생겼나: 루트(`/`) 범위의 **User Access Administrator** 1건(Owner, Contributor가 아님). 다른 사용자에게 Azure 역할을 줄 수 있는 역할입니다.
- 경고는 역할이 없어서인가: 역할 목록은 읽혔고 PowerShell도 1건을 돌려줬습니다. 경고가 뜬 것과 목록이 읽힌 것이 함께 있습니다.
- 끈 뒤 목록이 안 열리는 것은 이상한가: 끄면 루트 범위 권한이 사라지므로 권한 없음 안내로 돌아오는 것이 정상적인 방향입니다(문서는 토글을 끄면 제거된다고 설명).

#### 경고 원인 확인

원인은 직접 입증하지 못했습니다. 확인한 것과 추정은 이렇게 나뉩니다.

- 확인한 것(11-04): 경고 문구는 `Microsoft.Authorization/denyAssignments/read`를 수행할 권한이 없거나 범위가 잘못되었다는 내용이고 "액세스 권한이 최근에 부여된 경우 자격 증명을 새로 고치세요"라는 안내가 붙어 있습니다(그림 6).
- 문서: User Access Administrator 역할의 작업에는 `*/read`와 `Microsoft.Authorization/*`가 들어 있습니다([Azure built-in roles: Privileged](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged)). 그래서 이 역할에 읽기 권한이 없어서 경고가 뜬다는 10/23의 추정은 문서와 맞지 않습니다.
- 추정: 켠 직후라 권한 반영이나 토큰·캐시가 아직 따라오지 않은 상태일 수 있습니다. 문서는 토큰과 캐시가 최대 30분 유지된다고 설명합니다([Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)). 이 글에서는 켠 지 약 1~2분 시점의 화면만 봤고, 30분 이상 둔 뒤 경고가 사라지는지는 시도하지 않았습니다.
- 시도하지 않은 것: 역할 정의를 바꾸거나 다른 역할로 대조하는 일은 권한 변경이라 하지 않았습니다.

#### 끈 뒤 루트 역할 목록 읽기

- 끈 뒤 루트 IAM 역할 목록을 GUI로 열기: 목록 자체가 열리지 않음(권한 없음). 11-04에 관리 그룹 개요에서 Tenant Root Group이 링크가 아니고 "이 관리 그룹을 볼 수 있는 권한이 없습니다." 안내가 나오는 것을 캡처했습니다(그림 7).
- 1~3회차(10/22 09:57~11:02:59, 10/23 09:46:43~09:50:23, 09:56:36~16:01:10)에 PowerShell로 루트 목록 읽기: 하지 않음
    - 이 세 번의 "제거됨" 근거는 감사 로그와 "권한 없음" 안내 복귀입니다.
- 4회차(22:02:46~22:08:48): 토글 끄기가 GUI로 실패해 PowerShell로 제거
    - `Get-AzRoleAssignment`로 제거 전 1건 → 제거 후 **0건**([끄지 못한 과정]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}))
- 5회차(22:28:48~10/24 00:58:50): PowerShell로 제거
    - 제거 뒤 같은 조회로 0건을 읽었다는 기록은 남아 있지 않아, 근거는 감사 로그 "removed"(15:58:50Z)입니다

![원복 후. Entra 속성 토글 아니요와 감사 로그 제거 기록]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 3. 원복 후(위: Entra 속성 토글 = "아니요", 새로 불러온 화면, 22:09 / 아래: 감사 로그 조회에서 제거 기록 "The role assignment of User Access Administrator has been removed from the user"가 보임). 화면 속 가장 최근 기록은 13:08:48Z(= 22:08:48 KST)로, 5회차 켬 이전에 찍은 화면입니다. 계정 이름은 가렸습니다.*

![PowerShell로 지운 항목의 세부 정보. 사용자 에이전트에 Azure PowerShell이 보임]({{ "/assets/images/2026/10/m12-3c-audit-detail-ps.png" | relative_url }})
*그림 4. 22:08:48 "removed" 항목의 세부 정보(GUI). 범주와 상태는 같고, 사용자 에이전트에 `cloud-shell … AzurePowershell`이 찍혀 있어 이 제거가 화면 토글이 아니라 Cloud Shell의 PowerShell 호출이었음을 로그로도 확인할 수 있습니다. 상관관계 ID는 가렸고, 아래쪽 개체, 세션, IP, 계정 항목은 게시하지 않았습니다.*

#### 2026-11-04 재현: 켠 상태의 경고와 끈 뒤의 안내

10/23에는 경고 화면을 캡처하지 못해서, 2026-11-04에 같은 순서(켬 → 루트 IAM 열기 → 끔 → 관리 그룹 개요 확인)를 다시 수행하고 캡처했습니다. 시각은 KST이고 작업 뒤 토글은 "아니요"로 되돌렸습니다.

![Elevate를 켠 상태의 루트 관리 그룹 액세스 제어(IAM): 상단 주황 안내와 User Access Administrator 할당]({{ "/assets/images/2026/10/m12-13-root-iam-elevate-on-1104.png" | relative_url }})

*그림 5. 11-04 17:27경, 켠 상태의 Tenant Root Group > 액세스 제어(IAM). 상단에 "조치 필요: 이 테넌트에서 1 사용자가 상승된 액세스 권한입니다…" 안내가 나오고, 관리자 계정(이름 가림)에게 User Access Administrator가 범위 "루트(상속됨)"로 활성 영구 할당되어 있습니다(활성 1, 적격 0, 거부 0).*

![루트 IAM의 denyAssignments/read 권한 없음 경고]({{ "/assets/images/2026/10/m12-15-root-iam-denyassignments-warning-1104.png" | relative_url }})

*그림 6. 11-04 17:32경 다시 켠 뒤 같은 화면을 열었을 때 나타난 두 번째 경고(개체 ID, 계정, 테넌트 ID는 가렸습니다). "…범위에서 'Microsoft.Authorization/denyAssignments/read' 작업을 수행할 권한이 없거나 범위가 잘못되었습니다. 액세스 권한이 최근에 부여된 경우 자격 증명을 새로 고치세요."라고 적혀 있습니다.*

![Elevate를 끈 뒤 관리 그룹 개요에서 Tenant Root Group에 마우스를 올린 모습: 이 관리 그룹을 볼 수 있는 권한이 없습니다]({{ "/assets/images/2026/10/m12-14-root-tooltip-off-1104.png" | relative_url }})

*그림 7. 11-04 17:30경, 끈 상태의 관리 그룹 개요. Tenant Root Group은 링크가 아니고 마우스를 올리면 "이 관리 그룹을 볼 수 있는 권한이 없습니다."라는 안내가 나옵니다(ID와 구독 이름은 가렸습니다). 클릭해도 루트 IAM으로 들어가지 않았습니다.*

</details>

### 3. 결론

Elevate 끔 → 루트 범위 권한 제거 → 루트 IAM 목록 안 열림(정상) → 토글·감사 로그·0건 조회로 확인

- 사례 1 경고(그림 6): 역할에 `denyAssignments/read`가 없어서라는 10/23 추정은 문서(User Access Administrator에 `*/read` 포함)와 맞지 않습니다. 켠 직후의 권한 반영 지연일 가능성은 추정이고, 오래 둔 뒤의 재확인은 하지 않았습니다.
- 끈 뒤 루트 역할 목록 직접 확인: 확인 불가(시도: 목록 열기와 Tenant Root Group 클릭, 사유: 링크가 아니고 권한 없음 안내(그림 7), 다음 방법: 대체 근거 사용).

### 4. 권고방안

1. Elevate는 쓰고 나면 끄고, 켬·끔 시각을 기록합니다.
2. 조치 후 확인: 끈 뒤 PowerShell 조회와 감사 로그로 한 번 더 읽고, "제거됨"은 한 가지 근거로 단정하지 않습니다.
3. 역할 정의를 바꿔 확인하는 일은 권한 변경이라 하지 않습니다.

관련 글: [관리 그룹 설정이 403: Elevate access와 토큰]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}) · [Elevate를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}) · [Azure 구조: 계층, 리소스 그룹, Elevate access 전·후]({{ "/m365/d4-azure-structure/" | relative_url }})

### 근거 자료

> 이 글의 PowerShell 원문은 일부를 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 출력 캡처는 남기지 못했습니다.

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: Elevate access. 루트 `/`에서 User Access Administrator, 토글 끄기로 제거, 배너
    - 출처: [Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)
- 조회: 켠 상태 루트 IAM의 User Access Administrator 1건, PowerShell 1건, 끈 뒤 화면과 토글, 감사 로그, 제거 직후 0건
    - 출처: Azure 포털, Entra, Cloud Shell
- 문서: User Access Administrator는 `*/read`와 `Microsoft.Authorization/*`를 포함
    - 출처: [Azure built-in roles: Privileged](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged)
- 확인 불가: 끈 뒤 루트 역할 목록의 직접 확인, 경고의 정확한 원인(시도, 사유, 다음 방법은 2절 확인 과정의 '경고 원인 확인', '끈 뒤 루트 역할 목록 읽기')
    - 출처: -

</details>
