---
title: "[Troubleshooting] 동적 그룹 규칙이 얼마 만에 반응하는지 알 수 없다"
date: 2026-10-23 12:00:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 5
tags: [Troubleshooting, 동적 그룹, 반응 시간, Graph, 감사 로그]
excerpt: "부서 값을 바꾼 뒤 동적 그룹 구성원이 들어오고 나가기까지의 시간을 20초 간격 폴링과 감사 로그로 잰 기록. 들어올 때 9초, 나갈 때 5분 35초로 편차가 큼"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·막힌 이유·다음 방법 병기). 테넌트 ID·도메인·계정·사용자 이름은 게시하지 않았고, 시험 사용자는 "시험 사용자 2"처럼 적었습니다.

## 요약

| 구분 | 내용 |
|---|---|
| 증상 | 부서를 저장한 뒤 조회했을 때 구성원 1이 보였지만 시각을 기록하지 않아 반응 시간을 알 수 없음. 문서는 속성이 바뀌면 규칙이 다시 평가된다고만 설명 |
| 원인 | 측정 자체가 없었음 |
| 대처 | Cloud Shell에서 부서를 바꾼 시각부터 구성원 수를 약 20초 간격으로 읽고, Entra 감사 로그로 정확한 시각을 맞춤 |
| 결과 | 감사 로그 기준 들어올 때 9초, 나갈 때 5분 35초. 나갈 때 편차가 큼 |
| 운영 기준 | "즉시"로 가정하지 않고 변경 후 몇 분 기다린 뒤 확인. "1분 안쪽" 기준은 부족 |

---

## 전체 기록

### 1. 증상

동적 그룹 DG-Practice-02(규칙 `user.department -eq "Practice02"`)에서 시험 사용자 2의 부서를 Practice02로 저장한 뒤 조회하니 구성원 1이 보였고, 부서를 비우자 0으로 돌아왔습니다. 그러나 **저장 시각을 기록하지 않아** 몇 초 만에 반영되는지 알 수 없었습니다. 문서는 속성이 바뀌면 규칙이 다시 평가된다고만 설명합니다.

### 2. 먼저 확인할 것

1. 부서를 바꾼 시각을 기록한다 → 스크립트가 변경 직후 시각을 남김
2. 구성원 수를 일정 간격으로 읽는다 → 약 20초 간격, 목표 값이 되면 멈춤(최대 12회)
3. 폴링 간격 때문에 생기는 오차를 줄일 기준이 있는가 → Entra 감사 로그(Update user, Add/Remove member to group)의 정확한 시각

### 3. 시도와 결과

**1회차 측정(조회).** Cloud Shell에서 시험 사용자의 부서를 Practice02로 바꾼 시각(07:54:23 UTC)부터 DG-Practice-02의 구성원 수를 약 20초 간격으로 읽었습니다. +2초에는 0, **+23초에 1**이었습니다. 부서를 다시 비웠을 때(07:56:50 UTC)는 +23초에 1, **+44초에 0**으로 빠졌습니다. 이때의 화면은 글자가 작아 읽기 어려워 아래에서 다시 측정했습니다.

**2회차 측정(조회).** 같은 시험 사용자(시험 사용자 2, 부서가 비어 있던 사용자)로 스크립트를 다시 돌렸습니다. 부서를 Practice02로 바꾼 시각(12:29:42 UTC)에 구성원 0이었고 **+20초(12:30:03)에 1**이 되었습니다. 부서를 비운 시각(12:30:03 UTC)부터는 +331초(12:35:34)까지 계속 1이었고 **+352초(12:35:54)에 0**이 되었습니다. 부서 값이 비어 있다는 것도 같은 스크립트로 확인했습니다(출력 True).

![동적 그룹 구성원 수 변화를 20초 간격으로 읽은 Cloud Shell 출력]({{ "/assets/images/2026/10/m02-dyn-timing.png" | relative_url }})
*그림 1. 2회차 측정의 Cloud Shell 출력. 각 줄은 시각(UTC), 부서를 바꾼 뒤 경과 초, 구성원 수. 위에서부터 부서 입력 → 구성원 1 → 부서 비움 → 약 6분 뒤 구성원 0. 프롬프트의 계정 부분은 가렸다.*

**실행한 스크립트** (2회차에 돌린 것. 준비 코드 3줄: 토큰·`$h`·`$B`를 먼저 실행. 시험 사용자의 표시 이름은 게시하지 않아 자리표시로 적었습니다)

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

**Entra 감사 로그로 확인한 정확한 시각(GUI)**: Entra 관리 센터 > 모니터링 및 상태 > 감사 로그(최근 24시간, KST)에는 2회차 측정의 변경이 아래처럼 남아 있습니다. 폴링 값(위)과 모순 없이 맞습니다.

![Entra 감사 로그: 부서 변경, 그룹 가입·제거, 라이선스 변경 기록]({{ "/assets/images/2026/10/m02-dyn-audit.png" | relative_url }})
*그림 2. 21:29:42 Update user(부서 입력) → 21:29:51 Add member to group(그룹 가입) → 21:30:03 Update user(부서 비움) → 21:35:38 Remove member from group(그룹 제거) → 21:35:56 Change user license(그룹 라이선스 회수). 위쪽(최신)부터 아래쪽 순서로 읽는다.*

감사 로그 기준 정확한 값은 **들어올 때 9초(21:29:42→21:29:51), 나갈 때 5분 35초(21:30:03→21:35:38)** 입니다. 폴링 간격 때문에 생기는 구간 오차를 이 기록으로 줄였습니다. 그룹에서 빠진 뒤 약 18초 지나(21:35:56) 그룹 라이선스가 회수됐습니다.

| 측정 | 들어올 때(부서 입력 후 구성원 1) | 나갈 때(부서 비운 후 구성원 0) |
|---|---|---|
| 1회차(07:54 UTC) | +2초에는 0, +23초에 1 → 약 2~23초 | +23초에는 1, +44초에 0 → 약 23~44초 |
| 2회차(12:29 UTC) | 0초에는 0, +20초에 1 → 약 0~20초 | +331초에는 1, +352초에 0 → 약 331~352초 |

- **해석**: 들어올 때는 두 번 모두 약 20초 안에(2회차는 감사 로그 기준 9초) 반영됐지만, 나갈 때는 44초 이하에서 5분 35초까지 **편차가 매우 컸습니다**. 같은 사용자·같은 그룹이라도 반응 시간이 일정하지 않았습니다.
- **한계**: 각 방향 2회 측정, 폴링 간격 약 20초라 정확한 값이 아니라 **구간**입니다. 테넌트가 작고 그룹이 1개인 조건이라 규모가 큰 환경에서는 달라질 수 있습니다. 문서에서 규칙 처리가 지연될 수 있다는 설명은 **확인 불가**입니다(시도: 이번 측정에서 해당 문서를 다시 확인하지 않음, 막힌 이유: 측정만 진행함, 다음 방법: 동적 멤버십 문서에서 처리 시간 설명 확인).

### 4. 대처·원복

- 측정에 쓴 부서 값은 비워 원복했습니다. 비워진 것을 스크립트로 확인했습니다(출력 True, 2026-10-23 12:29~12:30 UTC 구간 작업).
- 그룹 DG-Practice-02는 그룹 라이선스를 먼저 제거한 뒤 삭제할 정리 항목으로 남겼습니다(삭제는 하지 않음).

### 5. 운영에서는 이렇게 판단한다

- 운영에서는 "즉시"라고 가정하지 않고, 변경 후 **몇 분 단위로 기다린 뒤** 확인하는 절차로 씁니다.
- 이 테넌트에서 나갈 때는 최대 5분 35초가 걸린 적이 있어, 기준을 "1분 안쪽"으로 잡으면 부족합니다.
- 그룹 가입·제거는 감사 로그(Add/Remove member to group)로 정확한 시각을 맞출 수 있고, 그룹 라이선스 반영·회수는 Change user license로 이어집니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 동적 그룹 규칙, P1 필요, 속성 변경 시 재평가 | [Dynamic membership rules](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership), [규칙 만들기](https://learn.microsoft.com/entra/identity/users/groups-create-rule) |
| 조회 | 1회차(07:54 UTC): 들어올 때 +2~23초, 나갈 때 +23~44초 | Cloud Shell(Graph) |
| 조회 | 2회차(12:29 UTC): 들어올 때 0~20초, 나갈 때 +331~352초 | Cloud Shell(Graph) |
| 조회 | 감사 로그 기준 들어올 때 9초, 나갈 때 5분 35초, 그룹 라이선스 회수는 그룹 제거 후 약 18초 | Entra 감사 로그 |
| 확인 불가 | 대규모 환경에서의 규칙 처리 지연(문서 설명 재확인 안 함) | 시도 방법·사유는 3절 |

관련 글: [Identity 구조 — 동적 그룹과 그룹 라이선스]({{ "/m365/d2-identity-groups/" | relative_url }}), [직접 라이선스와 그룹 라이선스가 겹침]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})
