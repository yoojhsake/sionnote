---
title: "[트러블슈팅] 루트 IAM에 경고가 뜨고, Elevate를 끈 뒤 루트 역할 목록이 열리지 않음"
date: 2026-10-23 22:40:00 +0900
categories: [m365, troubleshooting]
area: 로그인·권한
seq: 4
tags: [Azure, Elevate access, RBAC, 루트 IAM, denyAssignments, 감사 로그, 전체 기록]
excerpt: "켠 상태의 루트 IAM에 뜬 denyAssignments/read 경고의 원인과, 끈 뒤 루트 역할 목록을 직접 읽지 못해 대체 근거로 제거를 확인한 과정"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트 ID·구독 ID·도메인·계정은 가렸습니다. **Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.**

## 요약

| 항목 | 내용 |
|---|---|
| 증상 1 | Elevate를 켠 상태의 루트 IAM 화면에 `denyAssignments/read` 관련 경고가 뜸 |
| 증상 2 | Elevate를 끈 뒤에는 루트 IAM의 역할 목록이 열리지 않아, 할당이 제거됐는지 화면으로 직접 볼 수 없음 |
| 원인 | 1: **확인 불가**(부여된 역할에 그 읽기 권한이 포함되지 않기 때문일 수 있다는 추정만 있음). 2: 끈 뒤에는 루트 범위 권한이 없어 목록이 열리지 않음 |
| 대처 | 경고는 원인을 확정하지 않고 기록. 끈 뒤 확인은 토글 "아니요" + 관리 그룹 화면의 "권한 없음" 안내 복귀 + 감사 로그 "removed" + PowerShell 제거 직후 0건으로 대신함 |
| 결과 | "원복 완료"가 아니라 "토글 원복 확인 + 감사 로그 대조 + 제거 직후 0건 조회"로 표기 |

---

## 전체 기록

## 1. 증상

**켠 상태**: Elevate access를 켜고 재로그인한 뒤 루트 IAM(Tenant Root Group > 액세스 제어(IAM))을 열자 역할 할당 탭에 User Access Administrator가 범위 "루트 (상속됨)"으로 보이고, PowerShell `Get-AzRoleAssignment -Scope '/'`도 같은 1건을 돌려줬습니다(조회). 이 화면에 `denyAssignments/read` 관련 경고가 함께 떴습니다.

![Elevate 후. 루트 IAM 역할 할당 탭에 User Access Administrator가 범위 / 로 보이고, PowerShell도 같은 값]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 1. Elevate 후 상태(위: Entra 토글 "예" 22:02 / 가운데: Tenant Root Group > 액세스 제어(IAM)에서 User Access Administrator가 범위 "루트 (상속됨)"으로 보임, 10/24 00:56 / 아래: PowerShell `Get-AzRoleAssignment -Scope '/'`로 같은 값 확인, 00:56). 계정 이름은 가렸다. 토글은 22:02(4회차)에, 루트 IAM은 22:28에 켠 5회차 상태에서 찍어 시점이 다르다.*

**끈 뒤**: 토글을 "아니요"로 돌리자 관리 그룹 화면이 "권한 없음" 안내로 돌아왔고, 루트 IAM의 역할 할당 목록은 열리지 않았습니다. 그래서 "제거됐다"를 화면의 목록으로 직접 읽을 수 없었습니다.

![Elevate를 끈 뒤의 관리 그룹 화면]({{ "/assets/images/2026/10/m12-2-elevate-off-banner.png" | relative_url }})
*그림 2. Elevate를 끈 뒤(10/23 22:10)의 관리 그룹 화면(GUI). "디렉터리 관리자로 등록되어 있지만, 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다"라는 안내가 나오고, Tenant Root Group 이름이 더 이상 파란 링크가 아니다. 구독은 구독 자체에 대한 권한으로 계속 보인다. 구독 이름·ID·테넌트 ID는 가렸다.*

## 2. 먼저 확인할 것

| 확인 | 결과 |
|---|---|
| 켠 상태에서 무엇이 생겼나 | 루트(`/`) 범위의 **User Access Administrator** 1건(Owner·Contributor가 아님). 다른 사용자에게 Azure 역할을 줄 수 있는 역할 |
| 경고는 역할이 없어서인가 | 역할 목록은 읽혔고 PowerShell도 1건을 돌려줌. 경고가 뜬 것과 목록이 읽힌 것이 함께 있음 |
| 끈 뒤 목록이 안 열리는 것은 이상한가 | 끄면 루트 범위 권한이 사라지므로 권한 없음 안내로 돌아오는 것이 정상적인 방향(문서는 토글을 끄면 제거된다고 설명) |

## 3. 시도와 결과

### 3-1. 경고 원인 확인

원인은 **확인 불가**입니다. 부여된 역할(User Access Administrator)에 `denyAssignments/read` 읽기 권한이 포함되지 않기 때문일 수 있다는 추정만 있습니다.

| 시도 방법 | 막힌 이유 | 다음 방법 |
|---|---|---|
| 켠 상태의 루트 IAM 화면에서 경고 확인, 목록 조회 | 역할 정의를 바꾸거나 다른 역할을 받아 확인하는 것은 권한 변경이라 하지 않음 | 운영 환경에서 변경 권한이 있을 때 역할 정의 대조 |

### 3-2. 끈 뒤 루트 역할 목록 읽기

| 시도 | 결과 |
|---|---|
| 끈 뒤 루트 IAM 역할 목록을 GUI로 열기 | 목록 자체가 열리지 않음(권한 없음) |
| 1~3회차(10/22 09:57~11:02:59, 10/23 09:46:43~09:50:23, 09:56:36~16:01:10)에 PowerShell로 루트 목록 읽기 | 하지 않음. 이 세 번의 "제거됨" 근거는 감사 로그와 "권한 없음" 안내 복귀 |
| 4회차(22:02:46~22:08:48): 토글 끄기가 GUI로 실패해 PowerShell로 제거 | `Get-AzRoleAssignment`로 제거 전 1건 → 제거 후 **0건**([끄지 못한 과정]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }})) |
| 5회차(22:28:48~10/24 00:58:50): PowerShell로 제거 | 제거 뒤 같은 조회는 **0건** |

켜 둔 상태에서만 루트 목록을 볼 수 있어, 끈 뒤에 목록을 GUI로 직접 확인하는 방법은 없습니다.

![원복 후. Entra 속성 토글 아니요와 감사 로그 제거 기록]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 3. 원복 후(위: Entra 속성 토글 = "아니요", 새로 불러온 화면, 22:09 / 아래: 감사 로그 조회에서 제거 기록 "The role assignment of User Access Administrator has been removed from the user"가 보임, 10/24 00:5x 조회 화면). 계정 이름은 가렸다.*

![PowerShell로 지운 항목의 세부 정보. 사용자 에이전트에 Azure PowerShell이 보임]({{ "/assets/images/2026/10/m12-3c-audit-detail-ps.png" | relative_url }})
*그림 4. 22:08:48 "removed" 항목의 세부 정보(GUI). 범주·상태는 같고, **사용자 에이전트에 `cloud-shell … AzurePowershell`이 찍혀** 있어 이 제거가 화면 토글이 아니라 Cloud Shell의 PowerShell 호출이었음을 로그로도 확인할 수 있다. 상관관계 ID는 가렸고, 아래쪽 개체·세션·IP·계정 항목은 게시하지 않았다.*

## 4. 대처: 대체 근거로 확인

직접 목록으로는 끝내 확인하지 못하므로 "원복 완료"가 아니라 아래 대체 근거를 모아 **"토글 원복 확인 + 감사 로그 대조 + 제거 직후 0건 조회"**라고 씁니다.

| 대체 근거 | 값 | 증거 |
|---|---|---|
| Entra 속성 토글 | "아니요", 새로 불러온 화면에서 저장 버튼 비활성 | 조회 |
| 관리 그룹 화면 | "권한 없음" 안내로 복귀, Tenant Root Group 링크 없음(끈 직후 09:51, 16시경, 22:10) | 조회 |
| 감사 로그 | 켬·끔 시각 모두 기록, 제거는 "The role assignment of User Access Administrator has been removed from the user" | 조회 |
| PowerShell | 4회차·5회차 제거 직후 `Get-AzRoleAssignment` 0건 | 조회 |
| 루트 IAM 역할 목록(GUI) | 끈 뒤 열리지 않음 | **확인 불가**(시도: 끈 뒤 목록 열기 / 막힌 이유: 권한 없음으로 열리지 않음 / 다음 방법: 켠 상태에서만 볼 수 있어 직접 확인 방법 없음 → 위 대체 근거 사용) |

## 5. 운영에서는 이렇게 판단한다

- Elevate access는 "쓰고 나면 끄는" 기능입니다. **켠 시각과 끈 시각을 기록**하고, 끈 뒤에도 루트 범위 할당을 한 번 더 읽어 둡니다. GUI로는 읽을 수 없으니 PowerShell 조회와 감사 로그를 함께 씁니다.
- 끈 뒤 "제거됨"은 한 가지 근거로 단정하지 않고 토글, 안내 복귀, 감사 로그, 조회 결과를 겹쳐 적습니다.
- 켠 화면의 경고는 원인을 확정하지 못하면 추정과 시도·막힌 이유를 함께 적어 둡니다. 역할 정의를 바꿔 확인하는 일은 권한 변경이므로 하지 않습니다.

## 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access: 루트 `/`에서 User Access Administrator, 토글 끄기로 제거, 배너 | [Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 조회 | 켠 상태 루트 IAM의 User Access Administrator 1건, PowerShell 1건, 끈 뒤 화면·토글·감사 로그, 제거 직후 0건 | Azure 포털·Entra·Cloud Shell |
| 확인 불가 | denyAssignments 경고 원인, 끈 뒤 루트 역할 목록의 직접 확인(시도·사유·다음 방법은 3-1, 4번 표) | - |

> 이 글의 PowerShell 원문은 일부를 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.

관련 글: [관리 그룹 설정이 403 — Elevate access와 토큰]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}), [Elevate를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}), [Azure 구조 — 계층, 리소스 그룹, Elevate access 전·후]({{ "/m365/d4-azure-structure/" | relative_url }})
