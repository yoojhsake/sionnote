---
title: "[M365·Azure] Azure 구조 — 계층, 리소스 그룹, Elevate access 전·후 (전체 기록)"
date: 2026-10-22 10:00:00 +0900
categories: [m365]
phase: 구조 이해 실습
seq: 4
tags: [M365·Azure, Azure, 리소스 그룹, Elevate access, RBAC, 전체 기록]
excerpt: "Azure 계층 구조를 확인하고 비용 없는 리소스 그룹을 만든 뒤, 전역 관리자의 Elevate access 전·후·원복 상태와 범위별 역할 상속을 화면과 PowerShell로 비교한 전체 기록"
---

Azure 구조를 확인하는 실습입니다. M365·Azure 운영 준비의 일부라 M365 분류에 함께 둡니다.

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유 병기). 테넌트 ID·구독 ID·도메인·계정은 가렸습니다(그림의 검은 상자). **Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.**

## 요약

| 항목 | 결과 |
|---|---|
| 리소스 그룹 | 1개 → 3개. `rg-practice-d4-01`, `rg-practice-d4-02` / Korea Central / 상태 Succeeded / 리소스 없음(비용 없음) |
| Elevate 전 | 관리 그룹 화면에 "루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내, Entra 토글 "아니요" |
| Elevate 후 | 루트 IAM에 User Access Administrator(범위 `/`) 1건, PowerShell도 같은 값 |
| 원복 | 토글 "아니요", 화면이 전과 같은 안내로 복귀, 감사 로그에 켬·끔 시각이 모두 남음 |
| 켠 상태에서 읽은 관리 그룹 설정 | 기본 관리 그룹 Tenant Root Group, 계층 보호 Off |
| 역할 상속 | 리소스 그룹에 직접 준 Reader가 하위 범위에서는 상속으로, 형제 리소스 그룹에는 없음 |

---

## 전체 기록

## 1. 목표

1. Azure의 계층(테넌트 → 관리 그룹 → 구독 → 리소스 그룹 → 리소스)을 화면에서 확인한다.
2. **Azure 역할(RBAC)과 Entra 역할은 서로 다른 체계**임을 확인하고, 둘을 잇는 예외 통로인 **Elevate access**의 전·후를 값으로 비교한다.
3. 비용이 없는 리소스 그룹 2개를 만들어 생성 절차를 연습한다(VM 등 비용 리소스는 만들지 않음).
4. 범위별 역할 할당으로 "상위 범위의 역할이 하위로 상속된다"를 값으로 확인한다.

## 2. 먼저 알아야 할 개념

![관리 그룹, 구독, 리소스 그룹으로 이어지는 Azure 구조와 실습 결과]({{ "/assets/images/2026/10/d4-azure-hierarchy.png" | relative_url }})
*그림 1. Azure 구조와 실습 결과*

| 개념 | 쉬운 설명 |
|---|---|
| 계층 | 테넌트 > (루트) 관리 그룹 > 구독 > 리소스 그룹 > 리소스. 관리 범위(scope)로는 관리 그룹·구독·리소스 그룹·리소스 4단계 |
| RBAC 상속 | 상위 범위에 준 역할은 하위로 상속됨 |
| Entra 역할 ≠ Azure 역할 | 전역 관리자(Entra 역할)라고 해서 Azure 구독·리소스를 자동으로 관리할 수 있는 것은 아님 |
| 루트 관리 그룹 | 기본적으로 **아무도** 접근 권한이 없음. 전역 관리자만 스스로 권한을 올릴 수 있음 |
| Elevate access | 전역 관리자가 자기 자신에게 루트 범위(`/`)의 **User Access Administrator**를 부여하는 기능. 토글로 켜고 끔 |

전역 관리자인데 루트 관리 그룹이 안 열리는 것은 이 구조 때문입니다. 관리 그룹 설정을 읽을 때 나는 403(`settings/read` 권한 없음)도 같은 이유입니다.

켜면 생기는 권한은 **User Access Administrator**(루트 범위 `/`)이며 Owner나 Contributor가 아닙니다(조회). 이 역할은 다른 사용자에게 Azure 역할을 줄 수 있는 역할이라, 켜 둔 시간 동안은 **그 계정이 루트 범위에서 권한을 부여할 수 있는 상태**입니다. 그래서 필요한 시간 동안만 켜고 확인이 끝나면 즉시 끕니다.

## 3. 절차

### 3-1. 리소스 그룹 2개 만들기 (09:22)

1. portal.azure.com > 리소스 그룹 > + 만들기
2. 구독 선택, 이름 **rg-practice-d4-01**, 지역 **Korea Central**, 태그 `purpose=<프로그램명>-practice` > 검토 + 만들기 > 만들기
3. 같은 방식으로 **rg-practice-d4-02**

![Azure 포털 리소스 그룹 목록. rg-practice-d4-01과 rg-practice-d4-02가 Korea Central에 표시됨]({{ "/assets/images/2026/10/d4-resource-groups.png" | relative_url }})
*그림 2. 리소스 그룹 목록 (빨간 상자: 새로 만든 2개, 계정·구독 정보는 가림)*

### 3-2. Elevate access 전 상태 기록 (09:52)

1. 포털 > 관리 그룹 > **Tenant Root Group** 클릭
2. Entra > 개요 > 속성 > "Azure 리소스에 대한 액세스 관리" 토글 확인(저장 안 함). 영문 문서 표기는 Microsoft Entra ID > Manage > Properties

![Elevate 전. 관리 그룹 화면의 권한 없음 안내와 Entra 속성의 토글 아니요]({{ "/assets/images/2026/10/d4-elevate-before.png" | relative_url }})
*그림 3. Elevate 전 상태(위: 관리 그룹 화면의 "디렉터리 관리자로 등록되어 있지만 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내, Tenant Root Group이 링크가 아님 / 아래: Entra 속성의 토글 = "아니요"). 위 화면은 22:10, 아래 화면은 22:02에 따로 찍어 이어 붙였다. 계정·구독 이름·ID는 가렸다.*

### 3-3. Elevate access 켜기 → 후 상태 기록 (09:57 켬)

1. Entra > 개요 > 속성 > Azure 리소스에 대한 액세스 관리 > **예** > 저장
2. **로그아웃 후 재로그인** (문서가 요구하는 단계. 재로그인 후에야 후 상태가 보였고, 켠 직후에는 화면이 그대로였음)
3. 포털 > 관리 그룹 > Tenant Root Group > 액세스 제어(IAM) > 역할 할당 탭
4. Cloud Shell에서 같은 값 조회

```powershell
Get-AzRoleAssignment -Scope '/' | Select DisplayName,RoleDefinitionName,Scope,ObjectType
# 출력(재구성): ROOT | User Access Administrator | / | User   ← 첫 열은 계정 이름을 게시하지 않으려고 "ROOT"로 바꿔 적은 표기이며 실제 출력 그대로가 아닙니다
```

![Elevate 후. 루트 IAM 역할 할당 탭에 User Access Administrator가 범위 / 로 보이고, PowerShell도 같은 값]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 4. Elevate 후 상태(위: Entra 토글 "예" 22:02 / 가운데: Tenant Root Group > 액세스 제어(IAM)에서 User Access Administrator가 범위 "루트 (상속됨)"으로 보임, 10/24 00:56 / 아래: PowerShell `Get-AzRoleAssignment -Scope '/'`로 같은 값 확인, 00:56). 계정 이름은 가렸다. 토글은 22:02(4회차)에, 루트 IAM은 22:28에 켠 5회차 상태에서 찍어 시점이 다르다.*

켠 상태에서는 관리 그룹 > 설정 화면도 읽혔습니다. 기본 관리 그룹은 **Tenant Root Group**, 계층 보호("새 관리 그룹을 만드는 데 쓰기 권한이 필요합니다" 스위치)는 **Off**입니다(조회). 값을 읽는 과정에서 생긴 토큰 문제와 REST 결과는 [관리 그룹 설정이 403일 때]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}) 글에 따로 적었습니다.

루트 IAM에는 `denyAssignments/read` 관련 경고가 함께 떴습니다. 원인은 확인 불가이며, 아래 [루트 IAM 경고와 끈 뒤 역할 목록]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }}) 글에 정리했습니다.

### 3-4. Elevate access 끄기 → 원복 확인 (11:02 끔)

1. 같은 계정으로 토글을 **아니요**로 바꾸고 저장
2. 관리 그룹 화면과 Entra 속성 토글을 다시 확인(페이지를 새로 불러온 상태)
3. 감사 로그(Entra > 모니터링 및 상태 > 감사 로그, 서비스 "Azure RBAC (Elevated Access)")에서 켬·끔 기록 확인

![원복 후. 관리 그룹 화면은 전과 같은 권한 없음 안내로 돌아왔고 토글은 아니요]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 5. 원복 후(위: Entra 속성 토글 = "아니요", 새로 불러온 화면, 22:09 / 아래: 감사 로그 조회에서 제거 기록 "The role assignment of User Access Administrator has been removed from the user"가 보임, 10/24 00:5x 조회 화면). 계정 이름은 가렸다.*

Elevate는 모두 다섯 번 켜고 껐습니다. 켠 시각과 끈 시각은 감사 로그 기록이고 표시 시각은 KST입니다(조회).

| 회차 | 켬 | 끔 | 끈 방법 | 비고 |
|---|---|---|---|---|
| 1 | 10/22 09:57:06 | 10/22 11:02:59 | Entra 화면 토글 | 전·후·원복 비교 |
| 2 | 10/23 09:46:43 | 10/23 09:50:23 | Entra 화면 토글 | 끈 직후(09:51) 관리 그룹 화면이 권한 없음 안내로 복귀 |
| 3 | 10/23 09:56:36 | 10/23 16:01:10 | Entra 화면 토글 | 켠 직후(09:58) 관리 그룹 설정 화면에 토큰 갱신 안내, 켠 채로 약 6시간 |
| 4 | 10/23 22:02:46 | 10/23 22:08:48 | **PowerShell로 역할 할당 제거** | GUI 끄기 2회 실패, [별도 글]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}) |
| 5 | 10/23 22:28:48 | 10/24 00:58:50 | PowerShell로 역할 할당 제거 | 루트 IAM 화면 캡처용 |

5회차는 켠 채로 약 2시간 30분이 지났습니다. 켠 뒤 캡처를 이어서 하려 했는데 작업이 중간에 멈춰 있었고, 재개하자마자 캡처를 마치고 곧바로 제거했습니다. 켜 둔 동안 이 계정으로 한 작업은 읽기 조회뿐이며 다른 변경은 없었습니다.

### 3-5. 범위별 역할 할당과 상속 확인

대상은 제가 만든 리소스 그룹 `rg-practice-d4-01`/`-02` 둘뿐이고, 구독·관리 그룹 범위에는 부여하지 않았습니다. 시험 사용자에게 **Reader**를 `rg-practice-d4-01`에만 주고, 하위 범위·형제 리소스 그룹에서 어떻게 보이는지 읽었습니다.

**처음 시도(16시): Azure CLI와 NSG.** 시험 사용자 1에게 `az role assignment create`로 Reader를 주고, 하위 리소스로 NSG(`zz-test-nsg`)를 만들었습니다. 결과는 같았습니다(상속 포함 Reader, 직접만 0건, 다른 그룹·구독에는 없음). 다만 두 가지가 마음에 걸렸습니다.

- 무료 리소스를 만들려고 `az network nsg create`를 실행했더니 이 구독에서 `Microsoft.Network` 공급자가 등록되어 있지 않아, **Azure CLI가 "등록해 드립니다" 하고 공급자를 자동 등록**했습니다(등록 성공까지 약 1분 30초). 공급자 등록은 구독 설정 변경이라 사전에 알리지 못한 점을 기록합니다. 시험 리소스를 지운 뒤 `az provider unregister`로 되돌렸고, 되돌리는 중에는 "Unregistering"이었다가 약 1분 뒤 다시 조회하니 **"Unregistered"**로 원래 상태가 되었습니다. 교훈: 구독에 처음 만드는 종류의 리소스는 만들기 전에 공급자 등록 상태부터 읽습니다.
- 이때 남긴 그림은 해상도가 낮았습니다.

**다시 수행(22시대): PowerShell과 빈 ARM 배포.** 공급자 등록이 필요 없는 **빈 ARM 배포**(리소스 0개)를 하위 범위로 쓰고, 시험 사용자 2에게 PowerShell로 부여했습니다. **공급자 등록 상태는 바꾸지 않았습니다.** 이 절차와 그림이 아래 기록입니다.

| 단계 | 한 일 | 결과 |
|---|---|---|
| 0 | GUI: Azure 포털 > 리소스 그룹 > rg-practice-d4-01 > 액세스 제어(IAM) > 역할 할당 탭 | 소유자 2건(모두 구독에서 상속됨)뿐, 독자(Reader) 없음 (그림 6) |
| 0-1 | GUI로 부여를 시도: 추가 > 역할 할당 추가 | 역할 목록이 134개이고 영문·한글 이름이 섞여 Reader를 찾기 어려워 **중간에 닫음**(저장하지 않음) |
| 1 | PowerShell로 시험 사용자 2의 기존 할당 수 조회 후, `New-AzRoleAssignment`로 **Reader**를 `rg-practice-d4-01` 범위에 부여 | 부여 전 0건 → 부여 성공(스크립트 1) |
| 2 | GUI: 같은 IAM 역할 할당 탭 새로 고침 | **독자 1건, 대상 시험 사용자 2, 범위 "이 리소스"** (그림 7) |
| 3 | 하위 범위로 쓸 **빈 ARM 배포**(리소스 0개) 생성 후 범위별 조회 | 하위 범위 "상속 포함" 1건(Reader, 범위는 부모 RG), "직접만" 0건 → **상속 확인** (그림 8) |
| 4 | GUI: 형제 리소스 그룹 rg-practice-d4-02 IAM | 소유자 2건뿐, Reader 없음 → 옆 그룹으로 번지지 않음 (그림 9) |
| 5 | 정리: Reader 할당 삭제, 빈 배포 삭제 | 시험 사용자 할당 0건, RG-01의 Reader 0건, 배포 0개 (그림 10) |
| 6 | GUI: rg-practice-d4-01 IAM 다시 확인 | 소유자 2건뿐 (그림 11) |

**스크립트 1 — 준비와 부여** (Cloud Shell, PowerShell)

```powershell
# (1) 준비: 구독·범위 문자열, 시험 사용자 조회, 부여 전 할당 수
$sub = (Get-AzContext).Subscription.Id
$rg  = "/subscriptions/$sub/resourceGroups/rg-practice-d4-01"
$rg2 = "/subscriptions/$sub/resourceGroups/rg-practice-d4-02"
$u   = Get-AzADUser -UserPrincipalName ((Get-AzADUser -DisplayName '<시험 사용자 표시 이름>').UserPrincipalName)
'user: ' + $u.DisplayName
'before (user, all scopes): ' + @(Get-AzRoleAssignment -ObjectId $u.Id).Count

# (2) 부여: 리소스 그룹 rg-practice-d4-01 범위에 Reader
New-AzRoleAssignment -ObjectId $u.Id -RoleDefinitionName 'Reader' -Scope $rg |
  Select-Object RoleDefinitionName, @{n='Scope';e={$_.Scope -replace $sub,'<sub>'}} | Format-List
```

**스크립트 2 — 하위 범위 만들기와 범위별 조회**

```powershell
# (3) 하위 범위 만들기: 리소스 0개짜리 빈 ARM 배포(공급자 등록이 필요 없음)
$t = @{ '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
        contentVersion = '1.0.0.0'; resources = @() }
New-AzResourceGroupDeployment -ResourceGroupName 'rg-practice-d4-01' -Name 'zz-test-empty-deploy' -TemplateObject $t |
  Select-Object DeploymentName, ProvisioningState | Format-List

# (4) 범위별 조회: 하위(상속 포함 / 직접만), 형제 리소스 그룹, 구독
$child = "$rg/providers/Microsoft.Resources/deployments/zz-test-empty-deploy"
function Show($label, $scope, [switch]$Direct) {
  $a = @(Get-AzRoleAssignment -ObjectId $u.Id -Scope $scope)
  if ($Direct) { $a = @($a | Where-Object { $_.Scope -eq $scope }) }
  '{0}: {1} count' -f $label, $a.Count
  $a | ForEach-Object { '    ' + $_.RoleDefinitionName + ' @ ' + ($_.Scope -replace $sub,'<sub>') }
}
Show 'RG-01 scope' $rg
Show 'RG-01 child (incl. inherited)' $child
Show 'RG-01 child (direct only)' $child -Direct
Show 'RG-02 scope' $rg2
Show 'Subscription scope' "/subscriptions/$sub"
```

**스크립트 3 — 정리와 확인**

```powershell
# (5) 정리: 내가 만든 Reader 할당과 빈 배포만 삭제한 뒤 0건 확인
Remove-AzRoleAssignment -ObjectId $u.Id -RoleDefinitionName 'Reader' -Scope $rg | Out-Null
Remove-AzResourceGroupDeployment -ResourceGroupName 'rg-practice-d4-01' -Name 'zz-test-empty-deploy' | Out-Null
'user assignments (all scopes): ' + @(Get-AzRoleAssignment -ObjectId $u.Id).Count
'deployments in RG-01: ' + @(Get-AzResourceGroupDeployment -ResourceGroupName 'rg-practice-d4-01').Count
'Reader at RG-01: ' + @(Get-AzRoleAssignment -Scope $rg -RoleDefinitionName 'Reader').Count
```

![역할 할당 전 IAM 화면]({{ "/assets/images/2026/10/m19-iam-before.png" | relative_url }})
*그림 6. GUI 경로: Azure 포털 > 리소스 그룹 > rg-practice-d4-01 > 액세스 제어(IAM) > 역할 할당. 부여 전(22:18). 소유자 2건은 범위가 "구독 (상속됨)"이다. 계정·서비스 주체 이름은 가렸다.*

![부여 뒤 IAM 화면]({{ "/assets/images/2026/10/m17-role-assign.png" | relative_url }})
*그림 7. 같은 화면, 부여 뒤(22:21). 독자 1건이 생겼고 범위가 "이 리소스"(= 이 리소스 그룹에 직접 부여)다. 이름·계정은 가렸다.*

![하위 범위 상속 조회 결과]({{ "/assets/images/2026/10/m16-role-inherit.png" | relative_url }})
*그림 8. 스크립트 2의 출력(PowerShell). RG-01 범위 Reader 1건 / 하위(배포) 범위 "상속 포함" 1건(Reader, 범위는 부모 RG) / 하위 "직접만" 0건 / RG-02 0건. 마지막 "Subscription scope" 줄은 구독과 그 아래 전체에서 찾은 결과라서, 범위가 RG-01인 한 건이 그대로 나온 것이다(구독 범위에 직접 할당이 없다는 뜻). 구독 ID는 `<sub>`로 바꿔 표시했다.*

![형제 리소스 그룹의 IAM]({{ "/assets/images/2026/10/m18-role-sibling.png" | relative_url }})
*그림 9. GUI: rg-practice-d4-02 > 액세스 제어(IAM) > 역할 할당(부여 중인 22:2x에 캡처). 소유자 2건뿐이고 독자가 없다. 이름은 가렸다.*

![정리 결과 출력]({{ "/assets/images/2026/10/m21-role-cleanup.png" | relative_url }})
*그림 10. 스크립트 3의 출력. 사용자 할당 0건, 배포 0개, RG-01의 Reader 0건.*

![정리 뒤 IAM 화면]({{ "/assets/images/2026/10/m20-iam-after.png" | relative_url }})
*그림 11. GUI: rg-practice-d4-01 > 액세스 제어(IAM) > 역할 할당. 정리 뒤(22:3x). 소유자 2건뿐이다. 이름은 가렸다.*

Elevate를 켠 상태에서 리소스 그룹 범위의 기존 할당을 조회했을 때도 구독 Owner는 구독 범위에서 상속되어 표시됐고 User Access Administrator는 루트(`/`) 범위였습니다(조회).

이 실습으로 "상위 범위의 역할은 하위로 상속된다"가 실제 값으로 확인되었습니다. 한편 관리 그룹·구독 범위의 할당은 기존 환경에 영향이 크므로 하지 않았고, 그 부분은 문서 근거로만 둡니다.

## 4. 전·후 비교

### 4-1. Elevate access

| 항목 | 전 (09:52) | 후 (09:57 켬 + 재로그인) | 원복 후 (11:02 끔) |
|---|---|---|---|
| Entra 토글 "Azure 리소스에 대한 액세스 관리" | 아니요 | 예 | **아니요** |
| Tenant Root Group 클릭 | "이 관리 그룹을 볼 수 있는 권한이 없습니다" | 접근 가능 | **전과 같은 안내로 복귀** |
| 상단 안내 | "디렉터리 관리자로 등록되었지만 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" | 루트 IAM에 "조치 필요: 이 테넌트에서 1 사용자가 상승된 액세스 권한입니다" 배너 | 전과 같은 안내로 복귀 |
| 루트 IAM 내 할당(활성) | 볼 수 없음 | 활성 1 | - |
| 루트 IAM 역할 할당 탭 | 볼 수 없음 | 관리자 계정에 **User Access Administrator**, 범위 `/`(화면 표기 "루트 (상속됨)") | 끈 뒤에는 이 탭이 열리지 않음 |
| PowerShell `Get-AzRoleAssignment -Scope '/'` | 권한 없음 | User Access Administrator, 범위 `/`, 형식 User 1건 (그림 4) | PowerShell로 제거 뒤 같은 조회는 0건 |
| 관리 그룹 설정 | HTTP 403(`settings/read` 권한 없음, 10/19 REST) | 포털 설정 화면에서 기본 관리 그룹 Tenant Root Group, 계층 보호 Off | 포털 화면은 같은 값, REST는 403 |
| 감사 로그(Entra) | - | 09:57 "상승" 기록 | 11:02 "해제" 기록 |

**변경 이력**

| 항목 | 내용 |
|---|---|
| 언제 | 3-4절의 표(다섯 회차, 감사 로그 기준) |
| 누가 | 제가 직접(샌드박스 관리자 계정) |
| 무엇을 | 전역 관리자의 Azure 리소스 접근 관리(Elevate access) 토글 |
| 전 → 후 | 아니요 → 예 → 아니요 |
| 왜 | 루트 관리 그룹 상태와 Azure 역할 체계를 값으로 확인, 관리 그룹 설정 값 확인 |
| 근거 | 화면·PowerShell, 감사 로그, 문서 아래 URL |
| 검증 결과 | 루트 IAM에서 User Access Administrator(`/`) 확인, 원복 후 화면과 토글이 전 상태와 같음, 감사 로그에 켬·끔 모두 기록 |
| 원복 방법 | 같은 토글을 아니요로 저장. GUI로 저장되지 않으면 루트 범위 User Access Administrator 할당을 PowerShell로 제거(실행 완료) |

### 4-2. 리소스 그룹과 구독 역할

| 항목 | 만들기 전 | 만든 후 |
|---|---|---|
| 리소스 그룹 수 | 1 (기존 1개는 Southeast Asia) | **3** |
| 새 그룹 | - | rg-practice-d4-01, -02 / Korea Central / 태그 purpose=<프로그램명>-practice / 상태 Succeeded |
| 리소스 | - | 없음 (VM 등은 만들지 않음, 비용 없음) |
| 구독 역할 | Owner 2건(사용자 1 + 서비스 사용자 1), 모두 영구 활성, 적격(PIM) 0 | 변화 없음 |

구독 Owner인 서비스 사용자의 상세는 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 2026-08-23이고 앱 소유 조직은 외부입니다(조회). 용도는 확인 불가입니다(시도: 서비스 사용자 상세 열기 / 막힌 이유: 설명 항목이 비어 있음 / 다음 방법: 계정 소유자에게 확인).

### 4-3. 역할 할당 실습

| 범위 | 부여 전 | 부여 후(Reader를 rg-practice-d4-01에 직접) | 정리 후 |
|---|---|---|---|
| rg-practice-d4-01 | 소유자 2건(구독에서 상속) | 독자 1건 추가, 범위 "이 리소스" | 소유자 2건 |
| 하위 범위(빈 ARM 배포) | - | 상속 포함 Reader 1건, 직접만 0건 | 배포 0개 |
| rg-practice-d4-02(형제) | 소유자 2건 | 독자 없음 | 소유자 2건 |
| 시험 사용자 2의 할당(전체 범위) | 0건 | 1건 | 0건 |

## 5. 검증

| 검증 | 결과 |
|---|---|
| 리소스 그룹 수 1→3, 새 그룹 Succeeded | 확인 |
| Elevate 전: 권한 없음 안내 + 토글 아니요 | 확인 |
| Elevate 후: 루트 IAM에 UAA(`/`), PowerShell ROOT 줄: User Access Administrator, 범위 /, 형식 User | 확인 |
| 감사 로그: 다섯 회차의 켬·끔 시각 | 확인 (표는 3-4절) |
| 원복 후: 토글 아니요, 관리 그룹 화면이 전과 같음 | 확인 (끈 직후(09:51)·16시경·22:11에도 같은 안내) |
| 원복 후 루트 역할 목록 | GUI에서는 목록이 열리지 않음. 4회차(22:08)·5회차(00:58)에 `Remove-AzRoleAssignment` 후 `Get-AzRoleAssignment`가 **0건**, 감사 로그에 "removed" 기록. 1~3회차는 이 방법으로 읽지 않았고 감사 로그와 "권한 없음" 안내 복귀가 근거 |
| 역할 상속: 리소스 그룹에 준 Reader가 하위 범위에 상속, 형제 그룹에는 없음 | 확인, 정리 뒤 0건 |

그래서 이 글은 원복을 "원복 완료"가 아니라 **"토글 원복 확인 + 감사 로그 대조 + 제거 직후 0건 조회"**라고 적습니다. 끈 뒤 루트 역할 목록을 GUI로 직접 보는 방법은 없습니다.

## 6. 운영에서는 이렇게 판단한다

- Azure 역할과 Entra 역할을 **한 표에 같이 놓고** 담당자를 정해 둡니다. "전역 관리자니까 구독도 다 본다"는 가정은 틀립니다.
- 구독 Owner가 영구 활성 2명이고 적격 할당이 0입니다. Entra PIM의 활성 역할 4건도 모두 영구 할당이고 적격은 0건입니다(조회). 문서는 구독 Owner를 최대 3명으로 제한하라고 권하고, Microsoft Entra ID P2가 있으면 PIM으로 시간제 활성화(적격)를 쓸 수 있습니다. 이 테넌트는 P2가 있으나 적격 할당은 0입니다.
- Elevate access는 "쓰고 나면 끄는" 기능입니다. **켠 시각과 끈 시각을 기록**하고, 끈 뒤에도 루트 범위 할당을 한 번 더 읽어 둡니다.
- 켠 직후에 값이 안 읽히면 권한 부족으로 단정하기 전에 재로그인 같은 토큰 갱신부터 시도합니다.
- GUI 토글로 꺼지지 않으면 루트 범위 User Access Administrator 할당을 PowerShell/CLI로 제거하고 조회 0건과 감사 로그로 확인합니다.
- 구독에 처음 만드는 종류의 리소스는 만들기 전에 공급자 등록 상태부터 읽습니다. 비용이 나올 수 있는 구독(지출 한도 Off)에서는 연습을 **리소스 그룹처럼 비용 없는 객체**로만 합니다.

## 7. 작업 중 막힌 곳

| 상황 | 한 줄 대처 | 글 |
|---|---|---|
| 전역 관리자인데 관리 그룹 설정이 403, 켠 직후에도 값이 안 읽힘 | 루트 권한은 Elevate로만 받고, 값이 안 읽히면 토큰 갱신을 먼저 시도 | [관리 그룹 설정이 403일 때]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }}) |
| GUI 토글로 Elevate가 꺼지지 않음 | 루트 범위 User Access Administrator 할당을 PowerShell로 제거 | [Elevate를 GUI로 끄지 못할 때]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}) |
| 루트 IAM 경고, 끈 뒤 역할 목록이 열리지 않음 | 토글·화면·감사 로그·0건 조회를 대체 근거로 사용 | [루트 IAM 경고와 끈 뒤 역할 목록]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }}) |

## 8. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access: 루트 `/`에서 User Access Administrator, 로그아웃·재로그인, 토글 끄기로 제거, 배너 | [Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 문서 | 관리 그룹: 루트 "Tenant root group", 기본 접근 없음, 전역 관리자만 상승, 계층 6단계(루트와 구독 단계는 제외), RBAC 상속 | [Management groups](https://learn.microsoft.com/azure/governance/management-groups/overview) |
| 문서 | 관리 범위 4단계와 상속 | [Resource Manager 개요](https://learn.microsoft.com/azure/azure-resource-manager/management/overview) |
| 문서 | Azure 역할 vs Entra 역할 | [RBAC와 디렉터리 관리자 역할](https://learn.microsoft.com/azure/role-based-access-control/rbac-and-directory-admin-roles), [Entra 역할 개념](https://learn.microsoft.com/entra/identity/role-based-access-control/concept-understand-roles) |
| 문서 | 구독은 하나의 테넌트를 신뢰, Azure 역할 ≠ Entra 역할 | [구독과 디렉터리](https://learn.microsoft.com/entra/fundamentals/how-subscriptions-associated-directory) |
| 문서 | 리소스 관리 보안 | [Secure resource management](https://learn.microsoft.com/entra/architecture/secure-resource-management) |
| 문서 | 리소스 그룹 만들기 | [Manage resource groups (portal)](https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal) |
| 문서 | 구독 Owner 최대 3명 권장 등 | [Best practices for Azure RBAC](https://learn.microsoft.com/azure/role-based-access-control/best-practices) |
| 문서 | 적격·시간제 역할 할당(PIM 연동) | [Eligible and time-bound assignments](https://learn.microsoft.com/azure/role-based-access-control/pim-integration) |
| 조회 | 리소스 그룹 1→3, Elevate 전·후·원복 화면, PowerShell ROOT 행, 감사 로그의 켬·끔 시각 | Azure 포털·Entra·Cloud Shell |
| 조회 | 범위별 역할 할당·상속, 형제 그룹, 정리 뒤 0건 | Azure 포털·Cloud Shell |
| 조회 | 구독 Owner 서비스 사용자 상세, PIM 활성 4건(모두 영구)·적격 0건 | Cloud Shell·Entra PIM |

## 9. 확인 불가로 남은 것

| 항목 | 시도 방법 | 막힌 이유 | 다음 방법 |
|---|---|---|---|
| 루트 IAM의 `denyAssignments/read` 경고 원인 | 켠 상태의 루트 IAM 화면 확인 | 부여된 역할에 그 읽기 권한이 포함되지 않기 때문일 수 있다는 추정만 가능. 역할 정의를 바꾸거나 다른 역할을 받아 확인하는 것은 권한 변경이라 하지 않음 | 운영 환경에서 변경 권한이 있을 때 역할 정의 대조 |
| Elevate에 사전 승인이 필요한지 | 가이드·문서 검색 | 조직 내부 규정이라 문서에 없음 | 내부 확인 |
| 켠 상태에서 관리 그룹 설정을 REST로 읽을 수 있는지 | 켠 상태에서는 포털 화면만 읽음 | REST는 호출하지 않아 값이 없음(끈 상태의 403만 확인) | Elevate를 켠 상태에서 같은 REST 스크립트 실행 |
| 포털 설정 화면이 끈 뒤에도 값을 보여 준 이유 | 끈 뒤 화면 새로 불러오기, REST 직접 호출 | 포털 내부 호출 경로를 볼 수 없음 | 브라우저 네트워크 로그로 설정 화면이 부르는 API 확인(자세한 내용은 [관리 그룹 설정이 403일 때]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }})) |
| 구독 Owner 서비스 사용자의 용도 | 서비스 사용자 상세 열기 | 설명 항목이 비어 있음 | 계정 소유자에게 확인 |

## 10. 정리·남은 일

- 리소스 그룹 2개는 **삭제하지 않았고** 정리 항목으로 남겼습니다.
- 범위별 역할 할당은 리소스 그룹 범위로 수행하고 되돌렸습니다(3-5). 관리 그룹·구독 범위는 하지 않았습니다.
- Microsoft.Network 공급자는 시험 뒤 등록 안 됨 상태로 되돌렸습니다.

> 이 글의 PowerShell 원문은 일부를 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.
