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

- 관리 그룹 계층 보호 설정을 REST로 읽으면 HTTP 403(`settings/read` 권한 없음). Elevate access를 켠 직후 포털 설정 화면도 권한 안내만 나오고 값이 없었음
- 루트 관리 그룹은 전역 관리자도 기본 권한이 없어 Elevate access가 필요함. 켠 직후 안 읽힌 이유는 토큰 문제로 추정했으나 직접 확인은 못 함
- 포털 주소 끝에 `?feature.refreshtoken=true`를 붙여 다시 불러오자 값이 읽힘
- 기본 관리 그룹 Tenant Root Group, 계층 보호 Off
- 끈 뒤에도 포털은 같은 값, REST는 403. "토큰 갱신이 값을 읽히게 했다"고는 단정 못 함

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다. 구독 ID도 게시하지 않았습니다. Elevate access 토글을 켜고 끄는 일은 제가 직접 했습니다.

---

## 전체 기록

### 1. 증상

10/19에 관리 그룹의 계층 보호 설정을 REST로 읽었을 때 HTTP 403(`settings/read` 권한 없음)이 나서 현재 값을 알 수 없었습니다. 그 뒤 Elevate access를 켜서 루트 범위 권한은 확인했지만([Azure 구조 글]({{ "/m365/d4-azure-structure/" | relative_url }})), 관리 그룹 설정 값은 기록하지 못한 상태였습니다.

10/23 09:56:36에 Elevate를 켜고(감사 로그) 직후인 09:58:28에 관리 그룹 설정을 열었는데 값이 읽히지 않았습니다. 화면에는 설정 읽기 권한이 없거나 권한을 최근에 받은 경우 토큰을 새로 고치라는 안내가 나왔습니다.

![관리 그룹 설정 화면의 권한 부족 안내]({{ "/assets/images/2026/10/m12-4-mg-settings-403.png" | relative_url }})
*그림 1. 10/23 09:58, Elevate를 켠 직후의 관리 그룹 > 설정 화면(당시 캡처, 해상도가 낮음). 파란 안내 상자가 설정 읽기 권한이 없다고 알리고 기본 관리 그룹 값 칸은 "권한 없음"으로 읽히지 않았습니다. 이 화면은 지금은 재현되지 않아(아래 "확정된 것과 확인 불가인 것" 참조) 다시 찍지 못했습니다. 계정, 테넌트 이름, ID는 가렸습니다.*

### 2. 원인과 대처

#### 확실한 것과 추정

확실한 것은 하나입니다. **REST로 직접 읽으려면 루트 권한(Elevate)이 필요하고, 없으면 10/19와 같은 403이 납니다.** 전역 관리자라도 Azure 루트 관리 그룹의 권한은 자동으로 주어지지 않으니 Elevate access를 켜야 합니다.

켠 직후 값이 안 읽힌 이유는 권한을 올린 뒤에도 이전 토큰이 남아 있었기 때문이라고 추정했습니다. 토큰을 갱신하자 값이 읽혔습니다. 하지만 끈 뒤에도 포털이 같은 값을 보여 줬기 때문에 이 추정은 증거가 부족합니다(아래 "끈 뒤에도 포털은 같은 값을 보여 줬다", "확정된 것과 확인 불가인 것").

#### 대처 순서

1. 루트 범위 권한이 필요하면 Elevate access를 **필요한 시간만** 켭니다. 켠 시각과 끈 시각은 감사 로그에 남습니다.
2. 켠 직후 값이 안 읽히면 재로그인하거나 `?feature.refreshtoken=true`로 토큰을 갱신해 다시 엽니다.
3. 읽은 뒤에는 곧바로 끕니다. 끄기가 GUI로 안 되면 [Elevate를 GUI로 끄지 못할 때]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}) 글의 절차를 씁니다.
4. 끈 뒤 관리 그룹 화면은 "권한 없음" 안내로 돌아옵니다(10/23 09:51, 16시경, 22:10에 확인).

| 결과 | 값 |
|---|---|
| 기본 관리 그룹 | Tenant Root Group |
| 계층 보호 | Off |

| 결과 | 값 |
|---|---|
| 기본 관리 그룹 | Tenant Root Group |
| 계층 보호 | Off |

### 3. 다음에 Elevate를 켤 때

Elevate를 켠 직후 값이 안 읽히면, 권한 부족으로 단정하기 전에 **토큰 갱신**(재로그인 또는 새로 고침)부터 해 봅니다.

포털 화면에서 읽히는 것과 REST나 PowerShell로 읽히는 것은 같지 않을 수 있습니다. 이번에도 끈 뒤에 포털은 읽히고 REST는 403이었습니다. 그래서 권한 검증은 증거가 되는 호출로 합니다.

켠 시간은 짧게 쓰고, 쓰고 나면 곧바로 끕니다. 켬과 끔은 감사 로그에 남으니 그 시각을 변경 이력에 같이 적습니다. PIM을 쓰는 경우 역할 비활성화만으로는 토글이 "아니요"로 돌아가지 않으므로, 토글을 먼저 끄고 비활성화합니다(문서).

### 4. 확인 과정

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

그래서 **"Elevate 후 토큰 갱신이 값을 읽히게 했다"는 결론은 증거가 부족합니다.** 확인된 것은 다음과 같습니다.

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
- 확실한 것은 REST로 직접 읽으려면 루트 권한(Elevate)이 필요하고, 없으면 10/19와 같은 403이 난다는 점입니다.

</details>

### 5. 관련 글

[Azure 구조: 계층, 리소스 그룹, Elevate access 전·후]({{ "/m365/d4-azure-structure/" | relative_url }}), [Elevate를 GUI로 끄지 못할 때]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }}), [루트 IAM 경고와 끈 뒤 역할 목록]({{ "/m365/troubleshooting/elevate-root-iam-role-list/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- **문서**: Elevate access 절차, 끄는 방법(할당 제거 포함), PIM 주의
    - 출처: [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)
- **문서**: 토큰과 캐시 30분, 갱신 방법
    - 출처: [Manage your Azure subscriptions at scale with management groups](https://learn.microsoft.com/azure/governance/management-groups/manage)
- **조회**: 기본 관리 그룹·계층 보호 값, 끈 뒤 화면, REST 403, 감사 로그 시각
    - 출처: Azure 포털, Entra, Cloud Shell
- **확인 불가**: 포털이 끈 뒤에도 값을 보여 준 이유, 켠 상태의 REST 결과(시도·사유·다음 방법은 4절 "확정된 것과 확인 불가인 것")
    - 출처: -

</details>
