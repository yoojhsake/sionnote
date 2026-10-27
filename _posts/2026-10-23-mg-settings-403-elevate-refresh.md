---
title: "[M365·Azure] 12 트러블슈팅 — 관리 그룹 설정이 403일 때, Elevate access와 REST 재현 (전체 기록)"
date: 2026-10-23 10:10:00 +0900
categories: [m365, troubleshooting]
tags: [Azure, 관리 그룹, Elevate access, 토큰, "403", 전체 기록]
excerpt: "10/19에 HTTP 403으로 못 읽은 관리 그룹 설정을 Elevate access를 켜서 읽은 과정, 10/23 밤 켬→끔 재실습에서 GUI 끄기가 실패해 PowerShell로 제거한 기록, 그리고 포털과 REST의 결과가 다른 점"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트 ID·구독 ID·도메인·계정은 게시하지 않았고, **Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.**

## 1. 증상

- 10/19: 관리 그룹의 계층 보호 설정을 REST로 읽으면 HTTP 403(settings/read 권한 없음). 현재 값을 알 수 없었습니다.
- 10/22: Elevate access를 켜서 루트 범위 권한은 확인했지만([D4 글]({{ "/m365/d4-azure-structure/" | relative_url }})), 관리 그룹 설정 값은 기록하지 못했습니다.

## 2. 원인 추적

1. **권한이 없는 상태에서의 403**: 전역 관리자라도 Azure 루트 관리 그룹의 권한은 자동으로 없습니다. 관리 그룹 화면에서 "권한 없음" 안내가 나오는 이유와 같습니다(10/22 D4 글).
2. **Elevate를 켰는데도 안 읽힘(10/23)**: 이날 Elevate는 두 번 켰습니다(아래 4번 항목). 두 번째로 켠 09:56:36 직후인 09:58:28에 관리 그룹 설정을 열었더니, 설정 읽기 권한이 없거나 권한을 최근에 받은 경우 토큰을 새로 고치라는 안내가 나오고 값은 읽히지 않았습니다.
3. **토큰 문제로 좁힘**: 문서는 권한을 올린 뒤 "로그아웃 후 다시 로그인해 액세스를 갱신"하라고 안내하고(문서: Elevate access 문서 Step 1-5), 관리 그룹 캐시와 토큰은 최대 30분 동안 유지되며 브라우저 새로 고침·재로그인·새 토큰 요청으로 갱신할 수 있다고 설명합니다(문서: 관리 그룹 관리 문서). 그래서 **권한을 올린 뒤에도 이전 토큰이 남아 있어서 읽지 못하는 것**으로 추정했습니다. (이 추정은 토큰 내용을 직접 디코딩해 확인한 것이 아니라 결과로 맞춘 것입니다.)

![관리 그룹 설정 화면의 권한 부족 안내]({{ "/assets/images/2026/10/m12-4-mg-settings-403.png" | relative_url }})
*그림 1. 10/23 09:58, Elevate를 켠 직후의 관리 그룹 > 설정 화면(당시 캡처, 해상도가 낮음). 파란 안내 상자가 설정 읽기 권한이 없다고 알리고 기본 관리 그룹 값 칸은 "권한 없음"으로 읽히지 않았다. 이 화면은 지금은 재현되지 않아(아래 3-1 참조) 다시 찍지 못했다. 계정·테넌트 이름·ID는 가렸다.*

### 2-1. REST로 같은 403 재현 (10/23 22:11, Elevate 끈 상태)

10/19에 막혔던 호출을 Cloud Shell에서 그대로 다시 불렀습니다. 루트 권한이 없는 상태에서 설정 읽기 API는 403(`AuthorizationFailed`)을 돌려줍니다. 메시지 끝에는 "권한을 최근에 받았다면 자격 증명을 새로 고치라"는 안내가 붙습니다.

```powershell
# 관리 그룹 설정 읽기 시도 (Elevate 꺼진 상태에서 403 재현)
$tid = (Get-AzContext).Tenant.Id
$r = Invoke-AzRestMethod -Method GET -Path "/providers/Microsoft.Management/managementGroups/$tid/settings/default?api-version=2021-04-01"
'HTTP ' + $r.StatusCode
$e = ($r.Content | ConvertFrom-Json).error
'code   : ' + $e.code
($e.message -replace '\. ', ".`n") -split ' (with object id|does not have|over scope)' | ForEach-Object { '  ' + $_.Trim() }
```

![관리 그룹 설정 읽기 REST 호출이 403으로 거부된 결과]({{ "/assets/images/2026/10/m12-rest403.png" | relative_url }})
*그림 1-1. GUI 경로 없음(PowerShell). Cloud Shell(PowerShell)에서 위 스크립트를 실행한 결과. `HTTP 403`, 코드 `AuthorizationFailed`, 거부된 동작은 `Microsoft.Management/managementGroups/settings/read`이다. 계정 이름·개체 ID·테넌트 ID는 가렸다.*

## 3. 값이 읽힌 방법(10/23 오전)과 그 한계

10/23 오전에는 포털 주소 끝에 `?feature.refreshtoken=true`를 붙여 포털을 다시 불러 토큰을 새로 받았습니다. 다시 열자 값이 읽혔습니다. 다만 아래 3-1에서 보듯 이것이 "토큰 갱신 때문"이라고 단정할 수는 없습니다. 같은 값이 Elevate를 끈 뒤에도 포털에서 읽혔기 때문입니다.

![Elevate를 켠 상태의 관리 그룹 목록]({{ "/assets/images/2026/10/m12-1-elevate-on-tree.png" | relative_url }})
*그림 2. 10/23 22:03에 Elevate를 다시 켠 상태에서 다시 찍은 관리 그룹 목록(GUI: Azure 포털 > 관리 그룹 > 개요). 루트인 Tenant Root Group 이름이 파란 링크로 열리고 그 아래에 구독이 보인다. 구독 이름·ID·테넌트 ID는 가렸다.*

![토큰 갱신 뒤 읽힌 관리 그룹 설정]({{ "/assets/images/2026/10/m12-5-mg-settings-default-id.png" | relative_url }})
*그림 3. 같은 시각, Elevate를 켠 상태의 관리 그룹 > 설정 화면(GUI). 기본 관리 그룹 값(가린 부분)이 채워지고, "새 관리 그룹을 만드는 데 쓰기 권한이 필요합니다" 스위치는 꺼짐(계층 보호 Off)으로 읽힌다. 이 화면은 Azure 포털 계정 선택 화면에서 다시 로그인한 직후 열었다.*

| 항목 | 10/19 (REST) | 10/23 (Elevate 켠 상태, 포털 화면) |
|---|---|---|
| 기본 관리 그룹 | 읽지 못함(403) | Tenant Root Group |
| 계층 보호 | 읽지 못함(403) | Off |

### 3-1. 정정: 포털 화면은 Elevate를 끈 뒤에도 값을 보여 줬다

처음 이 글을 쓸 때는 "토큰을 새로 받아서 읽혔다"고 정리했습니다. 10/23 밤에 Elevate를 끈 뒤 같은 화면을 다시 열어 보니 **끈 상태에서도 포털 설정 화면은 같은 값을 보여 줬습니다**(아래 그림 3-1, 끈 뒤 약 6분, 화면을 새로 불러온 상태). 반면 같은 시각 REST 호출은 위 그림 1-1처럼 403이었습니다.

![Elevate를 끈 뒤에도 값이 보이는 관리 그룹 설정 화면]({{ "/assets/images/2026/10/m12-6-settings-elevate-off.png" | relative_url }})
*그림 3-1. 10/23 22:14, Elevate를 끈 지 약 6분 뒤의 관리 그룹 > 설정 화면(GUI). 기본 관리 그룹 값과 스위치가 그림 3과 같게 읽힌다. 기본 관리 그룹 값은 가렸다.*

그래서 **"Elevate 후 토큰 갱신이 값을 읽히게 했다"는 결론은 증거가 부족합니다.** 확인된 것은 다음과 같습니다.

| 상황 | 포털 설정 화면 | REST(settings/read) |
|---|---|---|
| Elevate 켠 상태 | 읽힘(그림 3) | 이번에는 호출하지 않음 → **확인 불가** |
| Elevate 끈 상태 | 읽힘(그림 3-1) | 403 AuthorizationFailed(그림 1-1) |
| 10/23 09:58, 켠 직후 | 권한 안내 + 값 없음(그림 1) | 호출하지 않음 |

- 포털이 끈 뒤에도 값을 보여 준 이유는 **확인 불가**입니다(시도: 끈 뒤 화면 새로 불러오기, REST 직접 호출 / 막힌 이유: 포털 내부 호출 경로를 볼 수 없음 / 다음 방법: 브라우저 네트워크 로그로 설정 화면이 부르는 API 확인). 문서가 관리 그룹 캐시를 최대 30분 유지한다고 설명하므로 캐시일 가능성이 있지만, 이것도 확인한 것은 아닙니다.
- 확실한 것은 **REST로 직접 읽으려면 루트 권한(Elevate)이 필요하고, 없으면 10/19와 같은 403이 난다**는 점입니다. 켠 상태에서 REST가 읽히는지는 이번에 다시 확인하지 못했습니다.

## 4. 끈 뒤

Elevate는 10/23~24에 네 번 켜고 껐습니다. 오전 두 번은 위에 적은 대로이고, **3·4회차는 10/23 밤에 이미지를 다시 찍으려고 담당자가 허용해 준 범위에서 제가 직접 켰다 껐습니다.**

| 회차 | 켬 | 끔 | 끈 방법 |
|---|---|---|---|
| 1 | 09:46:43 | 09:50:23 | Entra 화면 토글 |
| 2 | 09:56:36 | 16:01:10 | Entra 화면 토글(켠 채로 약 6시간) |
| 3 | 22:02:46 | 22:08:48 | **PowerShell로 역할 할당 제거**(GUI 끄기 2회 실패) |
| 4 | 22:28:48 | 10/24 00:58:50 | PowerShell로 역할 할당 제거(루트 IAM 화면 캡처용) |

(감사 로그 기록, 표시 시각은 KST. 두 번째 켬은 처음 글에서 빠뜨렸던 것을 바로잡은 것입니다. **4회차는 켠 채로 약 2시간 30분이 지났습니다.** 켠 뒤 캡처를 이어서 하려 했는데 작업이 중간에 멈춰 있었고, 재개하자마자 캡처를 마치고 곧바로 제거했습니다. 켜 둔 동안 이 계정으로 한 작업은 읽기 조회뿐이며 다른 변경은 없었습니다.)

### 4-1. 3회차: GUI로 끄기가 실패해 PowerShell로 끈 과정 (10/23 밤)

1. **켜기**: Entra 관리 센터 > 속성 > "Azure 리소스에 대한 액세스 관리" 토글을 "예"로 바꿔 저장 → "테넌트 속성을 업데이트함"(22:02:46). 이어서 위 그림 2·3을 찍었습니다.
2. **끄기 1차 시도(GUI)**: 같은 토글을 "아니요"로 바꾸고 저장 → 오른쪽 위 알림에 **"테넌트 속성을 업데이트할 수 없음 — 권한이 부족하여 작업을 완료할 수 없습니다."**(오류). 새로 불러오니 토글은 그대로 "예"였습니다(감사 로그에도 "끔"이 없었음).
3. **끄기 2차 시도(GUI)**: 페이지를 새로 불러온 뒤 한 번 더 같은 순서로 저장 → 같은 오류. 이 알림은 화면에 확인만 하고 이미지로 저장하지 못했습니다(확인 불가가 아니라 **캡처 누락**이며, 다시 재현하려면 Elevate를 또 켜야 해서 하지 않았습니다).
4. **원인**: **확인 불가**입니다(시도: GUI 2회, 새로 불러오기 / 막힌 이유: 오류 메시지에 세부 사유가 없음 / 다음 방법: 오류 때 브라우저 네트워크 로그에서 호출과 응답 확인). 오전 두 번은 같은 토글로 꺼졌으므로 "끌 수 없는 설정"은 아닙니다.
5. **대체 방법(문서)**: Microsoft는 Elevate 해제 방법으로 PowerShell/CLI에서 루트(`/`) 범위의 User Access Administrator 할당을 제거하는 방법도 안내합니다. 제가 켠 할당(= 샌드박스 관리자 본인 1건)만 조회해 확인하고 제거했습니다.

```powershell
# Elevate 해제: 루트('/') 범위의 User Access Administrator 할당 조회 → 제거 → 0건 확인
$upn = '<관리자 UPN>'   # 게시용 표기. 실제 실행에는 샌드박스 관리자 UPN
Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator' |
  Select-Object DisplayName, SignInName, Scope, RoleDefinitionName | Format-List

Remove-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'User Access Administrator' -Scope '/'

'after-remove count: ' + @(Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator').Count
```

실행 결과: 조회 시 루트 범위 User Access Administrator 할당은 샌드박스 관리자 1건, 제거 후 조회는 **0건**이었습니다.

![Elevate 해제 결과를 감사 로그 API로 조회한 출력]({{ "/assets/images/2026/10/m12-audit-ps.png" | relative_url }})
*그림 4-2. PowerShell로 감사 로그(서비스 "Azure RBAC (Elevated Access)")를 조회한 최근 4건(시각은 UTC 표기, KST는 +9시간, 10/24 00:5x에 조회). 위에서부터 4회차 끔 15:58:50Z(= 00:58:50 KST), 4회차 켬 13:28:48Z(= 22:28:48), 3회차 끔 13:08:48Z(= 22:08:48), 3회차 켬 13:02:46Z(= 22:02:46)이다. 3회차 끔은 GUI 실패 뒤 PowerShell로 제거했을 때 생긴 "The role assignment of User Access Administrator has been removed from the user" 기록이다.*

```powershell
# 감사 로그 조회(위 출력의 스크립트). $B = https://graph.microsoft.com/v1.0, $h = Graph 토큰 헤더(앞선 글의 공통 준비 코드)
(Invoke-RestMethod -Headers $h -Uri "$B/auditLogs/directoryAudits?`$filter=loggedByService eq 'Azure RBAC (Elevated Access)'&`$top=4").value |
  ForEach-Object { '{0}Z  {1}' -f $_.activityDateTime.ToString('MM-dd HH:mm:ss'), $_.activityDisplayName }
```

그리고 GUI에서도 끈 상태로 돌아간 것을 확인했습니다. 페이지를 **새로 불러온** 뒤 토글이 "아니요"이고 저장 버튼이 비활성입니다.

![Elevate를 끈 뒤 새로 불러온 Entra 속성 화면]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 4-3. GUI 경로: Entra 관리 센터 > 속성 > "Azure 리소스에 대한 액세스 관리". 22:09, 새로 불러온 화면에서 "아니요". 계정 이름은 가렸다.*

그 전·후 화면도 같은 칸을 찍어 두었습니다(앞: 켜기 전 "아니요", 뒤: 켠 뒤 "예").

![켜기 전 화면]({{ "/assets/images/2026/10/d4-elevate-before.png" | relative_url }})
*그림 4-4. 켜기 전(22:02, "아니요"). 계정 이름은 가렸다.*

![켠 뒤 화면]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 4-5. 켜고 저장한 직후(22:02, "예"). 계정 이름은 가렸다.*

### 4-2. 감사 로그 화면(GUI)

첫 번째 끈 직후(10/23 09:51) 관리 그룹 화면은 "권한 없음" 안내로 돌아왔고, 16시경과 22:11에도 같은 안내를 확인했습니다(조회).

![Entra 감사 로그의 Elevate 기록]({{ "/assets/images/2026/10/m12-3-audit-elevate.png" | relative_url }})
*그림 4. GUI 경로: Entra 관리 센터 > 모니터링 및 상태 > 감사 로그 > 날짜 범위 "지난 7일", 서비스 "Azure RBAC (Elevated Access)"(표시 시각은 KST, 22:09 캡처). 여덟 줄이 보인다(22:09 캡처, 4회차 켬·끔은 그림 4-2에 있다): 10/22 09:57:06 켬, 11:02:59 끔, 10/23 09:46:43 켬, 09:50:23 끔, 09:56:36 켬, 16:01:10 끔, 22:02:46 켬, 22:08:48 끔("User has elevated their access…"가 켬, "The role assignment of User Access Administrator…"가 끔). 활동 이름은 칸 너비 때문에 잘려 보여, 아래 그림에서 한 줄을 열어 전체 이름을 확인했다.*

![감사 로그 세부 정보: 활동 유형 전체 이름]({{ "/assets/images/2026/10/m12-3b-audit-detail.png" | relative_url }})
*그림 4-1. 09:46:43 항목(1회차 켬)을 열어 본 세부 정보. 활동 유형은 "User has elevated their access to User Access Administrator for their Azure Resources", 범주는 AzureRBACRoleManagementElevateAccess, 상태는 success이다. 상관관계 ID는 가렸고, 아래쪽 개체·세션·IP·계정 항목은 화면에서 잘라 게시하지 않았다.*

![PowerShell로 지운 항목의 세부 정보. 사용자 에이전트에 Azure PowerShell이 보임]({{ "/assets/images/2026/10/m12-3c-audit-detail-ps.png" | relative_url }})
*그림 4-1b. 22:08:48 "removed" 항목의 세부 정보(GUI). 범주·상태는 같고, **사용자 에이전트에 `cloud-shell … AzurePowershell`이 찍혀** 있어 이 제거가 화면 토글이 아니라 Cloud Shell의 PowerShell 호출이었음을 로그로도 확인할 수 있다. 상관관계 ID는 가렸고, 아래쪽 개체·세션·IP·계정 항목은 게시하지 않았다.*

![Elevate를 끈 뒤의 관리 그룹 화면]({{ "/assets/images/2026/10/m12-2-elevate-off-banner.png" | relative_url }})
*그림 5. Elevate를 끈 뒤(10/23 22:10)의 관리 그룹 화면(GUI). "디렉터리 관리자로 등록되어 있지만, 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다"라는 안내가 나오고, Tenant Root Group 이름이 더 이상 파란 링크가 아니다(그림 2와 비교). 구독은 구독 자체에 대한 권한으로 계속 보인다. 구독 이름·ID·테넌트 ID는 가렸다.*

끈 뒤에는 화면에서 루트 역할 목록을 열 수 없어, 3회차는 `Get-AzRoleAssignment`로 제거 전 1건 → 제거 후 0건을 직접 읽었습니다(위 4-1). 오전의 1·2회차는 이 방법으로 확인하지 않았으므로, 그 두 번의 "제거됨" 근거는 감사 로그와 "권한 없음" 안내 복귀입니다.

## 5. 운영에서는 이렇게 판단한다

- Elevate를 켠 직후에 값이 안 읽히면 권한 부족으로 단정하기 전에 **토큰 갱신**(재로그인 또는 새로 고침)을 먼저 시도합니다.
- 포털 화면에서 읽히는 것과 REST/PowerShell로 읽히는 것은 **같지 않을 수 있습니다**(이번에는 끈 뒤에도 포털은 읽히고 REST는 403). 권한 검증은 증거가 되는 호출로 합니다.
- GUI 토글로 Elevate가 안 꺼질 때("권한이 부족하여" 오류)는 루트 범위의 User Access Administrator 할당을 PowerShell/CLI로 제거하고, 조회 0건과 감사 로그 "removed"로 확인합니다.
- 켠 시간은 짧게 쓰고, 쓰고 나면 곧바로 끕니다. 켬·끔은 감사 로그에 남으므로 시각을 변경 이력에 같이 적습니다.
- PIM을 쓰는 경우 역할 비활성화만으로는 토글이 "아니요"로 돌아가지 않습니다. 토글을 먼저 끄고 비활성화합니다(문서).

## 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access 절차, 끄는 방법(할당 제거 포함), PIM 주의 | [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 문서 | 토큰·캐시 30분, 갱신 방법 | [Manage your Azure subscriptions at scale with management groups](https://learn.microsoft.com/azure/governance/management-groups/manage) |
| 조회 | 기본 관리 그룹·계층 보호 값, 끈 뒤 화면, 감사 로그 시각 | Azure 포털·Entra |
