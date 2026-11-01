---
title: "[Troubleshooting] 관리 그룹 설정이 403: Elevate access를 켜도 값이 안 읽힐 때 (토큰과 REST)"
date: 2026-10-23 10:10:00 +0900
categories: [m365, troubleshooting]
area: 로그인·권한
seq: 2
tags: [Azure, 관리 그룹, Elevate access, 토큰, "403", REST, 전체 기록]
excerpt: "관리 그룹 설정이 403이면 Elevate access가 필요합니다. 토큰을 새로 받자 값이 읽혔지만 포털과 REST 결과가 달라 원인은 단정하지 못했습니다"
---

관리 그룹의 계층 보호 설정을 REST로 읽으면 403이고, Elevate access를 켠 직후 포털도 권한 안내만 보여 줍니다. 주소에 `?feature.refreshtoken=true`를 붙여 다시 불러오자 값(Tenant Root Group, 계층 보호 Off)이 읽혔지만, 토큰 갱신 덕분이라고 단정하지는 못했습니다.

## 요약

- 관리 그룹 설정을 REST로 읽으려면 Elevate가 필요하고 없으면 403이 남
- 켠 직후 값이 안 읽히면 재로그인이나 토큰 갱신부터 해 보면 됨
- 끈 뒤에도 포털에 값이 보인 이유는 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 구독 ID도 게시하지 않았습니다. Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.

---

## 전체 기록

### 1. 증상

- 사례 1(10/19): 관리 그룹 계층 보호 설정을 REST로 읽으면 HTTP 403(`settings/read` 권한 없음).
- 사례 2(10/23): 09:56:36에 Elevate를 켜고 09:58:28에 설정을 열자 토큰을 새로 고치라는 안내만 나옴.

![관리 그룹 설정 화면의 권한 부족 안내]({{ "/assets/images/2026/10/m12-4-mg-settings-403.png" | relative_url }})
*그림 1. 10/23 09:58, Elevate를 켠 직후의 관리 그룹 > 설정 화면(당시 캡처, 해상도가 낮음). 파란 안내 상자가 설정 읽기 권한이 없다고 알리고 기본 관리 그룹 값 칸은 "권한 없음"으로 읽히지 않았습니다. 이 화면은 지금은 재현되지 않아(아래 "확정된 것과 확인 불가인 것" 참조) 다시 찍지 못했습니다. 계정, 테넌트 이름, ID는 가렸습니다.*

### 2. 원인 및 분석

전역 관리자에게도 루트 관리 그룹 권한은 자동으로 없고, 토큰과 캐시는 최대 30분 유지됩니다([Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin), [관리 그룹 관리](https://learn.microsoft.com/azure/governance/management-groups/manage)).

- 켜고 `?feature.refreshtoken=true`로 다시 불러온 뒤: 포털에 Tenant Root Group, 계층 보호 Off
- 끈 뒤(22:11~22:14): 포털은 같은 값 / REST는 403 `AuthorizationFailed`

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 4장)</summary>

#### 처음에 짚은 것

Elevate 상태부터 봤습니다. 전역 관리자라도 Azure 루트 관리 그룹의 권한은 자동으로 없고, 관리 그룹 화면에서 "권한 없음" 안내가 나오는 이유도 이것입니다(Azure 구조 글). 켜져 있는지는 Entra 속성의 토글과 감사 로그로 봅니다.

다음은 권한을 받은 시점입니다. 문서는 권한을 올린 뒤 "로그아웃 후 다시 로그인해 액세스를 갱신"하라고 안내합니다(문서: Elevate access 문서 Step 1-5). 또 관리 그룹 캐시와 토큰은 최대 30분 동안 유지되며 브라우저 새로 고침, 재로그인, 새 토큰 요청으로 갱신할 수 있다고 설명합니다(문서: 관리 그룹 관리 문서).

그래서 권한을 올린 뒤에도 이전 토큰이 남아 있어 읽지 못하는 것이라고 추정했습니다. 다만 이 추정은 토큰 내용을 직접 디코딩해 확인한 것이 아니라 결과로 맞춘 것입니다.

#### 토큰 갱신 후 값이 읽힘

포털 주소 끝에 `?feature.refreshtoken=true`를 붙여 포털을 다시 불러 토큰을 새로 받았습니다. 다시 열자 값이 읽혔습니다.

![Elevate를 켠 상태의 관리 그룹 목록]({{ "/assets/images/2026/10/m12-1-elevate-on-tree.png" | relative_url }})
*그림 2. 10/23 22:03에 Elevate를 다시 켠 상태에서 다시 찍은 관리 그룹 목록(GUI: Azure 포털 > 관리 그룹 > 개요). 루트인 Tenant Root Group 이름이 파란 링크로 열리고 그 아래에 구독이 보입니다. 구독 이름, ID, 테넌트 ID는 가렸습니다.*

![토큰 갱신 뒤 읽힌 관리 그룹 설정]({{ "/assets/images/2026/10/m12-5-mg-settings-default-id.png" | relative_url }})
*그림 3. 같은 시각, Elevate를 켠 상태의 관리 그룹 > 설정 화면(GUI). 기본 관리 그룹 값(가린 부분)이 채워지고, "새 관리 그룹을 만드는 데 쓰기 권한이 필요합니다" 스위치는 꺼짐(계층 보호 Off)으로 읽힙니다. 이 화면은 Azure 포털 계정 선택 화면에서 다시 로그인한 직후 열었습니다.*

| 항목 | 10/19 (REST, Elevate 없음) | Elevate 켠 상태(포털 화면) |
|---|---|---|
| 기본 관리 그룹 | 읽지 못함(403) | Tenant Root Group |
| 계층 보호 | 읽지 못함(403) | Off |

#### 끈 뒤에도 포털은 같은 값을 보여 줬다

처음에는 "토큰을 새로 받아서 읽혔다"고 봤습니다. 그런데 Elevate를 끈 뒤(22:08:48) 같은 화면을 다시 열어 보니 **끈 상태에서도 포털 설정 화면은 같은 값을 보여 줬습니다**(그림 4, 끈 뒤 약 6분, 화면을 새로 불러온 상태).

![Elevate를 끈 뒤에도 값이 보이는 관리 그룹 설정 화면]({{ "/assets/images/2026/10/m12-6-settings-elevate-off.png" | relative_url }})
*그림 4. 10/23 22:14, Elevate를 끈 지 약 6분 뒤의 관리 그룹 > 설정 화면(GUI). 기본 관리 그룹 값과 스위치가 그림 3과 같게 읽힙니다. 기본 관리 그룹 값은 가렸습니다.*

같은 시각 REST 호출은 10/19와 같은 403이었습니다. 10/19에 막혔던 호출을 Cloud Shell에서 그대로 다시 불렀습니다(22:11, Elevate 끈 상태).

루트 권한이 없는 상태에서 설정 읽기 API는 403(`AuthorizationFailed`)을 돌려주고, 메시지 끝에는 "권한을 최근에 받았다면 자격 증명을 새로 고치라"는 안내가 붙습니다.

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
*그림 5. GUI 경로 없음(PowerShell). Cloud Shell(PowerShell)에서 위 스크립트를 실행한 결과. `HTTP 403`, 코드 `AuthorizationFailed`, 거부된 동작은 `Microsoft.Management/managementGroups/settings/read`입니다. 계정 이름, 개체 ID, 테넌트 ID는 가렸습니다.*

#### 확정된 것과 확인 불가인 것

확인된 것은 다음과 같습니다.

| 상황 | 포털 설정 화면 | REST(settings/read) |
|---|---|---|
| 10/19, Elevate 없음 | - | 403 |
| 10/23 09:58, 켠 직후 | 권한 안내 + 값 없음(그림 1) | 호출하지 않음 |
| Elevate 켠 상태, 새로 불러온 뒤 | 읽힘(그림 3) | 이번에는 호출하지 않음(확인 불가) |
| Elevate 끈 상태(22:11~22:14) | 읽힘(그림 4) | 403 AuthorizationFailed(그림 5) |

- 포털이 끈 뒤에도 값을 보여 준 이유는 **확인 불가**입니다.
    - 시도: 끈 뒤 화면 새로 불러오기, REST 직접 호출
    - 막힌 이유: 포털 내부 호출 경로를 볼 수 없음
    - 다음 방법: 브라우저 네트워크 로그로 설정 화면이 부르는 API 확인
    - 문서가 관리 그룹 캐시를 최대 30분 유지한다고 설명하므로 캐시일 가능성이 있지만, 이것도 확인한 것은 아닙니다.
- 켠 상태에서 REST가 읽히는지는 **확인 불가**입니다.
    - 시도: 켠 상태에서는 포털 화면만 읽고 REST는 호출하지 않음
    - 막힌 이유: 호출하지 않아 값이 없음(끈 상태의 403만 확인)
    - 다음 방법: Elevate를 켠 상태에서 위 스크립트 실행

</details>

### 3. 결론

Elevate 없음 → REST 403 / 켠 직후 이전 토큰(추정) → 갱신 후 포털에 값 표시

REST로 읽으려면 Elevate가 필요합니다. 토큰 갱신 덕분이라는 추정은 끈 뒤에도 포털에 값이 보여 증거가 부족합니다.

확인 불가: 끈 뒤에도 포털에 값이 보인 이유(캐시 때문인지도 확인 불가), 켠 상태의 REST 결과(시도·사유는 확인 과정 "확정된 것과 확인 불가인 것"에).

### 4. 권고방안

1. Elevate는 필요한 시간만 켜고 켬·끔 시각을 변경 이력에 적습니다. PIM을 쓰면 토글을 먼저 끕니다(문서).
2. 켠 직후 값이 안 읽히면 재로그인하거나 `?feature.refreshtoken=true`로 토큰을 갱신합니다.
3. 조치 후 확인: 권한 검증은 REST·PowerShell 호출로 하고, 끈 뒤 관리 그룹 화면이 "권한 없음"으로 돌아오는지 봅니다(10/23 09:51, 16시경, 22:10 확인). 안 꺼지면 [Elevate를 GUI로 끄지 못할 때]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}).

관련 글: [Azure 구조: 계층, 리소스 그룹, Elevate access 전·후]({{ "/m365/d4-azure-structure/" | relative_url }}) · [루트 IAM 경고와 끈 뒤 역할 목록]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- **문서**: Elevate access 절차, 끄는 방법(할당 제거 포함), PIM 주의
    - 출처: [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)
- **문서**: 토큰과 캐시 30분, 갱신 방법
    - 출처: [Manage your Azure subscriptions at scale with management groups](https://learn.microsoft.com/azure/governance/management-groups/manage)
- **조회**: 기본 관리 그룹·계층 보호 값, 끈 뒤 화면, REST 403, 감사 로그 시각
    - 출처: Azure 포털, Entra, Cloud Shell
- **확인 불가**: 포털이 끈 뒤에도 값을 보여 준 이유, 켠 상태의 REST 결과(시도·사유·다음 방법은 2절 확인 과정 "확정된 것과 확인 불가인 것")
    - 출처: -

</details>
