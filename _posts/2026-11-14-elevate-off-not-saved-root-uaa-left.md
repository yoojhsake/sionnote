---
title: "[Troubleshooting] Elevate access를 끄고 저장했는데 루트 권한이 그대로 남아 있을 때"
date: 2026-11-14 23:40:00 +0900
categories: [azure, troubleshooting]
area: 로그인·권한
seq: 1
tags: [Troubleshooting, Azure, Elevate access, User Access Administrator, 감사 로그, Cloud Shell, PowerShell]
excerpt: "토글을 아니요로 바꾸고 저장까지 눌렀지만 루트 User Access Administrator는 3시간 동안 남아 있었다. 앱의 역할 할당 조회로 발견했고, 감사 로그에 끔 기록이 없는 것으로 저장 실패를 확인했다"
toc: true
---

Elevate access 토글을 "아니요"로 바꾸고 저장을 눌렀는데, 3시간 뒤 앱(서비스 주체)으로 역할 할당을 읽어 보니 관리자 본인의 루트(`/`) 범위 User Access Administrator가 그대로 남아 있었습니다. 감사 로그에는 켠 기록만 있고 끈 기록이 없었습니다. 같은 조작을 다시 해 보니 저장할 때 "권한이 부족하여 작업을 완료할 수 없습니다" 알림이 잠깐 떴다가 사라졌고, 화면의 토글은 "아니요"로 바뀐 채 그대로였습니다.

## 요약

- 저장 실패는 몇 초 뜨는 알림으로만 드러나고, 토글은 "아니요"로 보여서 꺼진 줄 알기 쉬움
- 끈 뒤에는 화면을 새로 불러와 토글을 보고, 루트 UAA가 0건인지 따로 조회해야 함
- 토글로 계속 안 꺼지면 루트 범위 UAA 할당을 PowerShell로 지우면 됨(1건 → 0건, 감사 로그에 제거 기록)
- Cloud Shell에서는 `(Get-AzContext).Account.Id`가 UPN이 아니라 `MSI@50342`라서 `-SignInName`으로 지우면 실패함. 개체 ID로 지워야 함
- 저장이 실패한 원인은 확인 불가

> 근거 표기: 조회 = 이 샌드박스 테넌트에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못한 해석. 그림의 사용자 이름, 계정(UPN), 테넌트 이름·ID, 개체 ID는 회색 상자로 가렸습니다. Elevate access를 켜고 끈 것은 모두 샌드박스 관리자 본인 계정입니다.

---

## 전체 기록

### 1. 증상

- 18:58에 Elevate access를 켜고 루트 관리 그룹에 앱 역할을 준 뒤, 19:02에 토글을 "아니요"로 바꾸고 저장을 눌렀습니다(그림 1). 알림은 확인하지 못했습니다.
- 22:04에 앱(서비스 주체)으로 구독의 역할 할당을 읽자 결과에 **역할 User Access Administrator, 할당 범위 `/`, 대상 관리자 본인** 행이 있었습니다(조회: 원천 데이터).
- 23:22에 같은 조작(토글 "아니요" → 저장)을 다시 해 보니 "테넌트 속성을 업데이트할 수 없음 — 권한이 부족하여 작업을 완료할 수 없습니다" 알림이 떴습니다(그림 2, 3). 새로 불러오면 토글은 "예"로 돌아와 있었습니다(그림 4). 저장 재시도 3회 모두 같았습니다(조회).

[![토글을 아니요로 바꾸고 저장 버튼을 누르는 화면]({{ "/assets/images/2026/11/ts-elevate-01-off-click.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-01-off-click.png" | relative_url }}){:target="_blank"}

*그림 1. 19:02, 토글 "아니요"와 같은 화면 아래쪽의 저장 버튼(두 부분을 이어 붙임). 이 뒤에 뜬 알림은 캡처하지 못했습니다.*

[![알림: 테넌트 속성을 업데이트할 수 없음, 권한이 부족하여 작업을 완료할 수 없습니다]({{ "/assets/images/2026/11/ts-elevate-02-error-toast.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-02-error-toast.png" | relative_url }}){:target="_blank"}

*그림 2. 23:22, 저장 직후 오른쪽 위에 몇 초 동안 뜬 알림.*

<details markdown="1">
<summary>알림 창과 새로 불러온 토글 (그림 2장)</summary>

[![알림 창에 남은 같은 오류]({{ "/assets/images/2026/11/ts-elevate-03-error-notification.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-03-error-notification.png" | relative_url }}){:target="_blank"}

*그림 3. 23:24, 종 모양 알림 창. 알림이 사라진 뒤에도 여기에는 남아 있어서 나중에 확인할 수 있습니다.*

[![새로 불러온 속성 화면: 토글이 다시 예]({{ "/assets/images/2026/11/ts-elevate-04-still-on-after-reload.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-04-still-on-after-reload.png" | relative_url }}){:target="_blank"}

*그림 4. 23:23, 토큰을 새로 받으며 다시 불러온 화면. 토글이 "예"입니다. 저장 전 화면에서는 "아니요"로 보였습니다.*

</details>

### 2. 원인 및 분석

기대값은 "아니요"로 저장하면 루트(`/`) 범위의 User Access Administrator 할당이 지워지고, 감사 로그에 제거 기록이 남는 것입니다(문서).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-elevate-dg-01-timeline-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-elevate-dg-01-timeline.png" | relative_url }}" alt="2026-11-14 Elevate access 켬·끔 시간표: 19:02 끔 실패, 22:04 발견, 22:10 끔, 23:22 실패, 23:26 Cloud Shell 제거" loading="lazy"></picture>

<details markdown="1">
<summary>감사 로그 네 건 (표)</summary>

감사 로그(서비스 "Azure RBAC (Elevated Access)", 지난 24시간)를 보니 이날 기록은 넷이었습니다(조회).

| 시각 | 활동 | 뜻 |
|---|---|---|
| 18:58:38 | User has elevated their access… | 켬 |
| 22:10:11 | The role assignment of User Access Administrator… | 끔(토글, 조회 결과를 보고 다시 끈 것) |
| 23:19:33 | User has elevated their access… | 켬(중복 역할 정리용) |
| 23:26:03 | The role assignment of User Access Administrator… | 끔(Cloud Shell에서 할당 제거) |

</details>

19:02에 끈 기록은 없습니다. 19:02의 저장은 반영되지 않았고, 22:10에 다시 끌 때까지 약 3시간 동안 루트 UAA가 남아 있었습니다(조회).

[![Entra 감사 로그: Azure RBAC (Elevated Access) 네 건]({{ "/assets/images/2026/11/ts-elevate-05-audit-log.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-05-audit-log.png" | relative_url }}){:target="_blank"}

*그림 5. Entra 관리 센터 > 감사 로그, 서비스 필터 "Azure RBAC (Elevated Access)"(23:29). 18:58 켬 다음 기록이 22:10 끔입니다.*

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 어떻게 발견했나

권한 검증용으로 앱이 구독의 역할 할당(Owner·User Access Administrator)을 상속분까지 읽고 있었습니다. 22:04 결과에 아래 행이 있었습니다(조회, 계정은 가림).

| 역할 | 할당 범위 | 할당 위치 | 대상 종류 |
|---|---|---|---|
| User Access Administrator | `/` | 상속(관리 그룹·루트) | User(관리자 본인) |

22:10에 토글로 다시 끈 뒤 22:26에 돌린 조회에서는 이 행이 없었습니다(조회). 화면 토글만 믿었다면 놓쳤을 상태를 역할 할당 조회가 잡은 셈입니다.

#### 실패 원인을 나눠 본 것

- **저장 요청이 갔는가**: 갔습니다. 알림 창에 "테넌트 속성을 업데이트할 수 없음"이 남았습니다(그림 3).
- **토큰이 오래돼서인가**: 주소에 `?feature.refreshtoken=true`를 붙여 다시 불러온 뒤에도 같은 오류였습니다(조회, 3회).
- **같은 토글이 원래 안 꺼지는가**: 아닙니다. 같은 날 22:10에는 같은 토글로 꺼졌습니다(그림 5).
- **오류의 세부 사유**: **확인 불가**
    - 시도: 알림 창의 메시지 확인, 브라우저 확장으로 네트워크 요청 읽기
    - 막힌 이유: 메시지에는 "권한이 부족하여"만 있고, 저장 요청은 포털 안의 다른 프레임에서 나가서 읽은 요청 목록에 잡히지 않았습니다
    - 다음 방법: 다시 실패할 때 브라우저 개발자 도구(F12)의 네트워크 탭에서 응답 본문을 확인

10/23에도 같은 문구로 끄기가 실패한 적이 있습니다([Elevate access를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }})). 그때는 11-04 재시험에서 재현되지 않았고, 이번에는 같은 날 두 번(19:02, 23:22) 실패했습니다. 두 사례의 공통 조건은 찾지 못했습니다.

</details>

### 3. 결론

`토글 "아니요" + 저장 → "권한이 부족하여" 알림(몇 초) → 저장 안 됨 → 화면은 "아니요"로 보임 → 루트 UAA 3시간 잔존 → 앱 조회로 발견 → 할당 제거 1건 → 0건`

끄기 실패는 알림이 사라지면 화면에서 드러나지 않습니다. 끈 것을 확인하는 기준은 화면 토글이 아니라 **새로 불러온 토글, 루트 UAA 0건, 감사 로그의 제거 기록** 세 가지입니다. 저장 실패의 원인은 확인 불가입니다.

### 4. 권고방안

1. 끈 뒤 화면을 새로 불러와 토글이 "아니요"인지 봅니다. 알림 창(종 모양)에 실패가 남았는지도 봅니다.
2. 루트 UAA가 0건인지 조회합니다. 남아 있으면 지웁니다. Cloud Shell(PowerShell)에서 아래 순서로 했습니다.

```powershell
# 1) 루트('/') 범위 User Access Administrator 조회
Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator' |
  Select-Object DisplayName, SignInName, RoleDefinitionName, Scope | Format-List

# 2) 제거: Cloud Shell에서는 Account.Id가 UPN이 아니므로 개체 ID로 지운다
'context account: ' + (Get-AzContext).Account.Id
$a = Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator'
'before: ' + @($a).Count
Remove-AzRoleAssignment -ObjectId $a.ObjectId -RoleDefinitionName 'User Access Administrator' -Scope '/'

# 3) 0건 확인
'after: ' + @(Get-AzRoleAssignment -Scope '/' -RoleDefinitionName 'User Access Administrator').Count
```

```text
DisplayName        : <관리자 이름>
SignInName         : <관리자 UPN>
RoleDefinitionName : User Access Administrator
Scope              : /

context account: MSI@50342
before: 1
Successfully removed role assignment for AD object '<개체 ID>' on scope '/' with role definition 'User Access Administrator'
after: 0
```

처음에는 `Remove-AzRoleAssignment -SignInName (Get-AzContext).Account.Id ...`로 지우려 했는데 `Cannot find principal using the specified options`로 실패했고 건수는 1 그대로였습니다(조회). Cloud Shell에서 `Account.Id`를 찍어 보니 로그인한 UPN이 아니라 `MSI@50342`였습니다(조회). Cloud Shell이 관리 ID 방식으로 토큰을 받기 때문으로 보입니다(추정: 이 값의 형식을 설명하는 문서는 찾지 못함). 그래서 조회 결과의 개체 ID로 지웠습니다.

[![Cloud Shell: context account MSI@50342, before 1, Successfully removed, after 0]({{ "/assets/images/2026/11/ts-elevate-06-cloudshell-removed.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-06-cloudshell-removed.png" | relative_url }}){:target="_blank"}

*그림 6. Cloud Shell(23:26). 제거 전 1건, 제거 후 0건입니다. 화면을 지우는 `clear`를 같은 줄에 넣어 2)의 명령 줄은 화면에서 지워졌고, 실행한 명령은 위 스크립트와 같습니다. 개체 ID와 계정은 가렸습니다.*

[![새로 불러온 속성 화면: 토글 아니요]({{ "/assets/images/2026/11/ts-elevate-07-off-after-reload.png" | relative_url }})]({{ "/assets/images/2026/11/ts-elevate-07-off-after-reload.png" | relative_url }}){:target="_blank"}

*그림 7. 제거 뒤 다시 불러온 Entra 속성(23:27). 토글이 "아니요"로 돌아왔습니다. 할당을 지우면 토글도 꺼진 상태로 읽힙니다(조회).*

3. 감사 로그에서 켬 다음에 끔 기록이 짝으로 있는지 봅니다(그림 5).
4. 루트 권한이 남는 것을 정기적으로 잡으려면, 정기 점검 조회에 "범위 `/`의 User Access Administrator"를 넣어 둡니다. 이번에 발견한 경로가 이것이었습니다.

관련 글: [앱 등록과 상황별 최소 권한 검증]({{ "/azure/app-registration-least-privilege/" | relative_url }}) · [Elevate access를 GUI로 끄지 못해 PowerShell로 끔]({{ "/m365/troubleshooting/elevate-off-gui-failure/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **문서**: Elevate access를 끄는 방법(토글, 루트 범위 User Access Administrator 할당 제거)
    - 출처: [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)
- **조회**: 22:04 조회의 루트 범위 UAA 행, 22:26 조회에서 사라짐
    - 출처: 앱(서비스 주체)의 역할 할당 조회 결과
- **조회**: 감사 로그 네 건(18:58 켬, 22:10 끔, 23:19 켬, 23:26 끔)
    - 출처: 그림 5
- **조회**: 저장 실패 알림, 새로 불러온 토글 "예", Cloud Shell 제거 1건 → 0건, `MSI@50342`, `-SignInName` 실패 메시지
    - 출처: 그림 2~4, 6, 4절
- **확인 불가**: 저장 실패의 세부 원인
    - 시도·사유·다음 방법은 2절 '확인 과정 자세히 보기'

</details>
