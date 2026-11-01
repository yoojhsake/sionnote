---
title: "[Troubleshooting] 동적 그룹 규칙이 얼마 만에 반응하는지 알 수 없다"
date: 2026-10-23 12:00:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 5
tags: [Troubleshooting, 동적 그룹, 반응 시간, Graph, 감사 로그]
excerpt: "부서를 바꾼 뒤 동적 그룹 반영을 재 보니 들어올 때 9초, 나갈 때 5분 35초. \"즉시\"로 가정하면 안 된다"
---

부서를 바꾸면 동적 그룹에는 얼마 만에 반영될까요? 구성원 수를 약 20초 간격으로 읽고 Entra 감사 로그로 시각을 맞춰 보니, 들어올 때는 9초였지만 나갈 때는 5분 35초가 걸렸습니다.

## 요약

- 같은 사용자와 그룹인데도 나갈 때 반응 시간의 편차가 매우 컸음
- 변경 후 몇 분 기다려 확인하고 정확한 시각은 감사 로그로 맞추면 됨
- 각 방향 2회 측정한 구간 값이라 큰 환경에서는 달라질 수 있음

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 시험 사용자는 "시험 사용자 2"처럼 적었습니다.

---

## 전체 기록

### 1. 증상

- DG-Practice-02(규칙 `user.department -eq "Practice02"`)에서 시험 사용자 2의 부서를 넣으면 구성원 1, 비우면 0이 됐지만 저장 시각을 기록하지 않아 반영 시간을 알 수 없었습니다.

### 2. 원인 및 분석

문서는 속성이 바뀌면 규칙이 다시 평가된다고만 설명합니다([Dynamic membership rules](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)). 그래서 직접 쟀습니다.

감사 로그 기준 들어올 때 9초(21:29:42→21:29:51), 나갈 때 5분 35초(21:30:03→21:35:38)였고, 약 18초 뒤(21:35:56) 그룹 라이선스가 회수됐습니다. 각 방향 2회 측정한 구간 값이고, 작은 테넌트와 그룹 1개 조건입니다.

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

#### 측정 방법

스크립트가 부서를 바꾼 직후 시각을 남기고, 그때부터 구성원 수를 약 20초 간격으로 읽다가 목표 값이 되면 멈추게 했습니다(최대 12회). 폴링 간격 때문에 생기는 오차는 Entra 감사 로그(Update user, Add/Remove member to group)의 정확한 시각으로 줄였습니다.

#### 1회차 측정(조회)

Cloud Shell에서 시험 사용자의 부서를 Practice02로 바꾼 시각(07:54:23 UTC)부터 DG-Practice-02의 구성원 수를 약 20초 간격으로 읽었습니다.

들어올 때는 +2초에는 0, +23초에 1이었습니다. 부서를 다시 비웠을 때(07:56:50 UTC)는 +23초에 1, +44초에 0으로 빠졌습니다.

이때의 화면은 글자가 작아 읽기 어려워서 한 번 더 측정했습니다.

#### 2회차 측정(조회)

같은 시험 사용자(시험 사용자 2, 부서가 비어 있던 사용자)로 스크립트를 다시 돌렸습니다.

부서를 Practice02로 바꾼 시각(12:29:42 UTC)에 구성원 0이었고 +20초(12:30:03)에 1이 되었습니다. 그런데 부서를 비운 시각(12:30:03 UTC)부터는 +331초(12:35:34)까지 계속 1이었고, **+352초(12:35:54)에야 0**이 되었습니다. 부서 값이 비어 있다는 것도 같은 스크립트로 확인했습니다(출력 True).

![동적 그룹 구성원 수 변화를 20초 간격으로 읽은 Cloud Shell 출력]({{ "/assets/images/2026/10/m02-dyn-timing.png" | relative_url }})
*그림 1. 2회차 측정의 Cloud Shell 출력. 각 줄은 시각(UTC), 부서를 바꾼 뒤 경과 초, 구성원 수. 위에서부터 부서 입력 → 구성원 1 → 부서 비움 → 약 6분 뒤 구성원 0. 프롬프트의 계정 부분은 가렸습니다.*

2회차에 돌린 스크립트입니다. 준비 코드 3줄(토큰, `$h`, `$B`)을 먼저 실행합니다. 시험 사용자의 표시 이름은 게시하지 않아 자리표시로 적었습니다.

<details markdown="1">
<summary>스크립트 전체 보기 (23줄)</summary>

```powershell
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
# 시험 사용자 2(부서가 비어 있던 사용자)와 동적 그룹 DG-Practice-02 (규칙: user.department -eq "Practice02")
$uid = (Invoke-RestMethod -Headers $h -Uri "$B/users?`$filter=displayName eq '<시험 사용자 2의 표시 이름>'&`$select=id").value.id
$gid = (Invoke-RestMethod -Headers $h -Uri "$B/groups?`$filter=displayName eq 'DG-Practice-02'&`$select=id").value.id
function Set-Dept($v) {      # 부서 값을 바꾸고 바꾼 시각을 기록 (값이 $null이면 비움)
  $body = @{ department = $v } | ConvertTo-Json
  Invoke-RestMethod -Method Patch -Headers $h -Uri "$B/users/$uid" -ContentType 'application/json' -Body $body | Out-Null
  $script:t0 = Get-Date
  '{0} UTC department -> {1}' -f $t0.ToUniversalTime().ToString('HH:mm:ss'), $(if ($v) { $v } else { '(empty)' })
}
function Wait-Count($want) { # 약 20초 간격으로 그룹 구성원 수를 읽어 want가 되면 멈춤(최대 12회)
  for ($i = 0; $i -lt 12; $i++) {
    $n = (Invoke-RestMethod -Headers $h -Uri "$B/groups/$gid/members?`$select=id").value.Count
    '{0} UTC +{1,3}s members={2}' -f (Get-Date).ToUniversalTime().ToString('HH:mm:ss'), [int]((Get-Date) - $t0).TotalSeconds, $n
    if ($n -eq $want) { break }; Start-Sleep 20
  }
}
$t0 = Get-Date; Wait-Count 0; Set-Dept 'Practice02'; Wait-Count 1; Set-Dept $null; Wait-Count 0
Wait-Count 0   # 12회(약 4분) 안에 0이 되지 않아 한 번 더 실행
(Invoke-RestMethod -Headers $h -Uri "$B/users/$uid`?`$select=department").department -eq $null   # 원복 확인(True)
```

</details>

#### Entra 감사 로그로 맞춘 시각(GUI)

Entra 관리 센터 > 모니터링 및 상태 > 감사 로그(최근 24시간, KST)에는 2회차 측정의 변경이 아래처럼 남아 있습니다. 위 폴링 값과 모순 없이 맞습니다.

![Entra 감사 로그: 부서 변경, 그룹 가입·제거, 라이선스 변경 기록]({{ "/assets/images/2026/10/m02-dyn-audit.png" | relative_url }})
*그림 2. 21:29:42 Update user(부서 입력) → 21:29:51 Add member to group(그룹 가입) → 21:30:03 Update user(부서 비움) → 21:35:38 Remove member from group(그룹 제거) → 21:35:56 Change user license(그룹 라이선스 회수). 위쪽(최신)부터 아래쪽 순서로 읽습니다.*

#### 두 측정 비교

- **1회차(07:54 UTC)**
    - 들어올 때(부서 입력 후 구성원 1): +2초에는 0, +23초에 1 → 약 2~23초
    - 나갈 때(부서 비운 후 구성원 0): +23초에는 1, +44초에 0 → 약 23~44초
- **2회차(12:29 UTC)**
    - 들어올 때: 0초에는 0, +20초에 1 → 약 0~20초
    - 나갈 때: +331초에는 1, +352초에 0 → 약 331~352초

#### 원복

부서 값은 비워 원복했습니다(출력 True, 2026-10-23 12:29~12:30 UTC 작업). DG-Practice-02는 그룹 라이선스 제거 후 삭제할 정리 항목으로 남겼습니다(삭제 안 함).

</details>

### 3. 결론

부서 변경 → 규칙 재평가 → 가입 9초, 제거 44초 이하~5분 35초(같은 사용자·그룹에서도 일정하지 않음)

문서에서 규칙 처리가 지연될 수 있다는 설명은 확인 불가입니다(시도: 해당 문서 재확인 안 함, 사유: 측정만 진행, 다음 방법: 동적 멤버십 문서의 처리 시간 설명 확인).

### 4. 권고방안

1. 동적 그룹 변경은 "즉시"로 가정하지 않고 몇 분 단위로 기다린 뒤 확인합니다("1분 안쪽"으로 잡으면 부족합니다).
2. 정확한 시각은 감사 로그의 Add/Remove member to group, Change user license로 맞춥니다.

관련 글: [Identity 구조: 동적 그룹과 그룹 라이선스]({{ "/m365/d2-identity-groups/" | relative_url }}) · [직접 라이선스와 그룹 라이선스가 겹침]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **문서**: 동적 그룹 규칙, P1 필요, 속성 변경 시 재평가
    - 출처: [Dynamic membership rules](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership), [규칙 만들기](https://learn.microsoft.com/entra/identity/users/groups-create-rule)
- **조회**: 1회차(07:54 UTC): 들어올 때 +2~23초, 나갈 때 +23~44초
    - 출처: Cloud Shell(Graph)
- **조회**: 2회차(12:29 UTC): 들어올 때 0~20초, 나갈 때 +331~352초
    - 출처: Cloud Shell(Graph)
- **조회**: 감사 로그 기준 들어올 때 9초, 나갈 때 5분 35초, 그룹 라이선스 회수는 그룹 제거 후 약 18초
    - 출처: Entra 감사 로그
- **확인 불가**: 대규모 환경에서의 규칙 처리 지연(문서 설명 재확인 안 함)
    - 시도 방법·사유는 3절

</details>
