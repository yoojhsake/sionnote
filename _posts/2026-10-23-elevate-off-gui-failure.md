---
title: "[Troubleshooting] Elevate access를 GUI로 끄지 못해 PowerShell로 끔"
date: 2026-10-23 22:20:00 +0900
categories: [m365, troubleshooting]
area: 로그인·권한
seq: 3
tags: [Azure, Elevate access, RBAC, PowerShell, 감사 로그, "권한이 부족", 전체 기록]
excerpt: "Entra 토글로 Elevate access를 끄려 하자 '권한이 부족하여' 오류가 두 번 나서, 루트 범위 User Access Administrator 할당을 PowerShell로 제거하고 감사 로그로 확인한 기록"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트 ID·구독 ID·도메인·계정은 게시하지 않았고, **Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.**

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | Entra의 "Azure 리소스에 대한 액세스 관리" 토글을 "아니요"로 저장하면 "테넌트 속성을 업데이트할 수 없음 — 권한이 부족하여 작업을 완료할 수 없습니다." 오류. 새로 불러오면 토글이 그대로 "예" |
| 원인 | **확인 불가**. 오류 메시지에 세부 사유가 없음. 오전에는 같은 토글로 꺼졌으므로 "끌 수 없는 설정"은 아님 |
| 대처 | 문서가 안내하는 대체 방법으로 루트(`/`) 범위의 User Access Administrator 할당을 PowerShell로 제거. 제가 켠 할당(샌드박스 관리자 본인 1건)만 조회해 확인하고 제거 |
| 결과 | 제거 전 1건 → 제거 후 **0건**. 감사 로그에 "removed" 기록, 사용자 에이전트에 Cloud Shell의 Azure PowerShell. 토글은 새로 불러온 화면에서 "아니요" |

---

## 전체 기록

## 1. 증상

1. **켜기**: Entra 관리 센터 > 속성 > "Azure 리소스에 대한 액세스 관리" 토글을 "예"로 바꿔 저장 → "테넌트 속성을 업데이트함"(22:02:46).
2. **끄기 1차 시도(GUI)**: 같은 토글을 "아니요"로 바꾸고 저장 → 오른쪽 위 알림에 **"테넌트 속성을 업데이트할 수 없음 — 권한이 부족하여 작업을 완료할 수 없습니다."**(오류). 새로 불러오니 토글은 그대로 "예"였습니다. 감사 로그에도 "끔"이 없었습니다.
3. **끄기 2차 시도(GUI)**: 페이지를 새로 불러온 뒤 한 번 더 같은 순서로 저장 → 같은 오류.

이 오류 알림은 화면에 확인만 하고 이미지로 저장하지 못했습니다. 확인 불가가 아니라 **캡처 누락**이며, 다시 재현하려면 Elevate를 또 켜야 해서 하지 않았습니다.

![켜기 전 화면]({{ "/assets/images/2026/10/d4-elevate-before.png" | relative_url }})
*그림 1. 켜기 전. 위: 관리 그룹 화면의 "디렉터리 관리자로 등록되어 있지만 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내(22:10), 아래: Entra 속성의 토글 "아니요"(22:02). 계정 이름은 가렸다.*

![켠 뒤 화면]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 2. 켠 뒤. 위: 켜고 저장한 직후 토글 "예"(22:02), 가운데·아래: 루트 IAM의 User Access Administrator(범위 "루트 (상속됨)")와 PowerShell `Get-AzRoleAssignment -Scope '/'`(00:56, 5회차 켬 상태). 계정 이름은 가렸다.*

## 2. 먼저 확인할 것

| 확인 | 결과 |
|---|---|
| 끄기가 저장됐는가 | 새로 불러온 화면에서 토글이 그대로 "예", 감사 로그에 "끔" 없음 → 저장되지 않음 |
| 같은 토글이 원래 꺼지는 설정인가 | 이날 앞선 두 번(09:50:23, 16:01:10)은 같은 토글로 꺼졌음 → "끌 수 없는 설정"은 아님 |
| 오류 원인 | **확인 불가**. 시도: GUI 2회, 새로 불러오기 / 막힌 이유: 오류 메시지에 세부 사유가 없음 / 다음 방법: 오류 때 브라우저 네트워크 로그에서 호출과 응답 확인 |
| 켜져 있는 동안의 위험 | User Access Administrator는 다른 사용자에게 Azure 역할을 줄 수 있는 역할이라, 켜 둔 시간만큼 루트 범위 권한 부여가 가능한 상태 → 오래 두지 않고 다른 방법으로 끈다 |

## 3. 시도와 결과

### 3-1. 대체 방법: 루트 범위 할당을 PowerShell로 제거

Microsoft는 Elevate 해제 방법으로 PowerShell/CLI에서 루트(`/`) 범위의 User Access Administrator 할당을 제거하는 방법도 안내합니다(문서). 제가 켠 할당(= 샌드박스 관리자 본인 1건)만 조회해 확인하고 제거했습니다.

```powershell
# Elevate 해제: 루트('/') 범위의 User Access Administrator 할당 조회 → 제거 → 0건 확인
$upn = '<관리자 UPN>'   # 게시용 표기. 실제 실행에는 샌드박스 관리자 UPN
Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator' |
  Select-Object DisplayName, SignInName, Scope, RoleDefinitionName | Format-List

Remove-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'User Access Administrator' -Scope '/'

'after-remove count: ' + @(Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator').Count
```

실행 결과: 조회 시 루트 범위 User Access Administrator 할당은 샌드박스 관리자 1건, 제거 후 조회는 **0건**이었습니다. 제거 시각은 22:08:48입니다.

> 이 글의 PowerShell 원문은 일부를 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 출력 값은 실제와 같습니다.

### 3-2. 감사 로그(PowerShell)로 켬·끔 확인

```powershell
# 감사 로그 조회(아래 출력의 스크립트). $B = https://graph.microsoft.com/v1.0, $h = Graph 토큰 헤더(공통 준비 코드로 만든 값)
(Invoke-RestMethod -Headers $h -Uri "$B/auditLogs/directoryAudits?`$filter=loggedByService eq 'Azure RBAC (Elevated Access)'&`$top=4").value |
  ForEach-Object { '{0}Z  {1}' -f $_.activityDateTime.ToString('MM-dd HH:mm:ss'), $_.activityDisplayName }
```

![Elevate 해제 결과를 감사 로그 API로 조회한 출력]({{ "/assets/images/2026/10/m12-audit-ps.png" | relative_url }})
*그림 3. PowerShell로 감사 로그(서비스 "Azure RBAC (Elevated Access)")를 조회한 최근 4건(시각은 UTC 표기, KST는 +9시간, 10/24 00:5x에 조회). 위에서부터 5회차 끔 15:58:50Z(= 00:58:50 KST), 5회차 켬 13:28:48Z(= 22:28:48), 4회차 끔 13:08:48Z(= 22:08:48), 4회차 켬 13:02:46Z(= 22:02:46)이다. 4회차 끔은 GUI 실패 뒤 PowerShell로 제거했을 때 생긴 "The role assignment of User Access Administrator has been removed from the user" 기록이다.*

### 3-3. 감사 로그(GUI)와 화면 확인

GUI 경로: Entra 관리 센터 > 모니터링 및 상태 > 감사 로그 > 날짜 범위 "지난 7일", 서비스 "Azure RBAC (Elevated Access)".

![Entra 감사 로그의 Elevate 기록]({{ "/assets/images/2026/10/m12-3-audit-elevate.png" | relative_url }})
*그림 4. 감사 로그 목록(표시 시각은 KST, 22:09 캡처). 여덟 줄이 보인다(5회차 켬·끔은 그림 3에 있다): 10/22 09:57:06 켬, 11:02:59 끔, 10/23 09:46:43 켬, 09:50:23 끔, 09:56:36 켬, 16:01:10 끔, 22:02:46 켬, 22:08:48 끔("User has elevated their access…"가 켬, "The role assignment of User Access Administrator…"가 끔). 활동 이름은 칸 너비 때문에 잘려 보여, 아래 그림에서 한 줄을 열어 전체 이름을 확인했다.*

![감사 로그 세부 정보: 활동 유형 전체 이름]({{ "/assets/images/2026/10/m12-3b-audit-detail.png" | relative_url }})
*그림 5. 09:46:43 항목(2회차 켬)을 열어 본 세부 정보. 활동 유형은 "User has elevated their access to User Access Administrator for their Azure Resources", 범주는 AzureRBACRoleManagementElevateAccess, 상태는 success이다. 상관관계 ID는 가렸고, 아래쪽 개체·세션·IP·계정 항목은 화면에서 잘라 게시하지 않았다.*

![PowerShell로 지운 항목의 세부 정보. 사용자 에이전트에 Azure PowerShell이 보임]({{ "/assets/images/2026/10/m12-3c-audit-detail-ps.png" | relative_url }})
*그림 6. 22:08:48 "removed" 항목의 세부 정보(GUI). 범주·상태는 같고, **사용자 에이전트에 `cloud-shell … AzurePowershell`이 찍혀** 있어 이 제거가 화면 토글이 아니라 Cloud Shell의 PowerShell 호출이었음을 로그로도 확인할 수 있다. 상관관계 ID는 가렸고, 아래쪽 개체·세션·IP·계정 항목은 게시하지 않았다.*

GUI에서도 끈 상태로 돌아간 것을 확인했습니다. 페이지를 **새로 불러온** 뒤 토글이 "아니요"이고 저장 버튼이 비활성입니다. 관리 그룹 화면도 "권한 없음" 안내로 돌아왔고 Tenant Root Group 이름이 더 이상 파란 링크가 아닙니다.

![Elevate를 끈 뒤 새로 불러온 Entra 속성 화면]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 7. GUI 경로: Entra 관리 센터 > 속성 > "Azure 리소스에 대한 액세스 관리". 22:09, 새로 불러온 화면에서 "아니요". 계정 이름은 가렸다.*

![Elevate를 끈 뒤의 관리 그룹 화면]({{ "/assets/images/2026/10/m12-2-elevate-off-banner.png" | relative_url }})
*그림 8. Elevate를 끈 뒤(10/23 22:10)의 관리 그룹 화면(GUI). "디렉터리 관리자로 등록되어 있지만, 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다"라는 안내가 나오고, Tenant Root Group 이름이 더 이상 파란 링크가 아니다. 구독은 구독 자체에 대한 권한으로 계속 보인다. 구독 이름·ID·테넌트 ID는 가렸다.*

## 4. 대처와 원복

Elevate는 다섯 번 켜고 껐습니다(감사 로그 기록, 표시 시각은 KST).

| 회차 | 켬 | 끔 | 끈 방법 |
|---|---|---|---|
| 1 | 10/22 09:57:06 | 10/22 11:02:59 | Entra 화면 토글 |
| 2 | 10/23 09:46:43 | 10/23 09:50:23 | Entra 화면 토글 |
| 3 | 10/23 09:56:36 | 10/23 16:01:10 | Entra 화면 토글(켠 채로 약 6시간) |
| 4 | 10/23 22:02:46 | 10/23 22:08:48 | **PowerShell로 역할 할당 제거**(GUI 끄기 2회 실패) |
| 5 | 10/23 22:28:48 | 10/24 00:58:50 | PowerShell로 역할 할당 제거(루트 IAM 화면 캡처용) |

5회차는 켠 채로 약 2시간 30분이 지났습니다. 켠 뒤 캡처를 이어서 하려 했는데 작업이 중간에 멈춰 있었고, 재개하자마자 캡처를 마치고 곧바로 제거했습니다. 켜 둔 동안 이 계정으로 한 작업은 읽기 조회뿐이며 다른 변경은 없었습니다.

끈 뒤에는 화면에서 루트 역할 목록을 열 수 없어, 4회차는 `Get-AzRoleAssignment`로 제거 전 1건 → 제거 후 0건을 직접 읽었습니다(3-1). 1~3회차는 이 방법으로 확인하지 않았으므로, 그 세 번의 "제거됨" 근거는 감사 로그와 "권한 없음" 안내 복귀입니다. 끈 뒤 루트 역할 목록이 열리지 않는 문제는 [루트 IAM 경고와 끈 뒤 역할 목록]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }}) 글에 따로 적었습니다.

## 5. 운영에서는 이렇게 판단한다

- GUI 토글로 Elevate가 안 꺼질 때("권한이 부족하여" 오류)는 루트 범위의 User Access Administrator 할당을 PowerShell/CLI로 제거하고, 조회 0건과 감사 로그 "removed"로 확인합니다. 제거 대상은 본인이 켠 할당 1건뿐인지 먼저 조회합니다.
- 켠 시간은 짧게 쓰고, 쓰고 나면 곧바로 끕니다. 켬·끔은 감사 로그에 남으므로 시각을 변경 이력에 같이 적습니다.
- 감사 로그의 사용자 에이전트를 보면 토글로 껐는지 PowerShell 호출로 제거했는지 구별됩니다.
- PIM을 쓰는 경우 역할 비활성화만으로는 토글이 "아니요"로 돌아가지 않습니다. 토글을 먼저 끄고 비활성화합니다(문서).
- 오류 알림은 사라지기 전에 캡처합니다. 이번에는 알림을 이미지로 남기지 못했습니다.

## 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access 절차, 끄는 방법(할당 제거 포함), PIM 주의 | [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 조회 | 루트 범위 User Access Administrator 제거 전 1건 → 후 0건, 감사 로그 시각, 사용자 에이전트 | Cloud Shell·Entra 감사 로그 |
| 조회 | 끈 뒤 토글 "아니요", 관리 그룹 화면의 "권한 없음" 안내 복귀 | Entra·Azure 포털 |
| 확인 불가 | GUI 끄기 실패의 원인, 오류 알림 캡처(시도·사유·다음 방법은 2번 표) | - |

관련 글: [관리 그룹 설정이 403 — Elevate access와 토큰]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}), [Azure 구조 — 계층, 리소스 그룹, Elevate access 전·후]({{ "/m365/d4-azure-structure/" | relative_url }})
