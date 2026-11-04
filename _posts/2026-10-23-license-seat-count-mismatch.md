---
title: "[Troubleshooting] 라이선스 사용 수가 기록(18/25)과 조회(20/25)로 다르다"
date: 2026-10-23 11:00:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 6
tags: [Troubleshooting, 라이선스, 좌석 수, 사용자 수, 기록 대조]
excerpt: "라이선스 사용 수가 기록은 18/25, 조회는 20/25입니다. 날짜별 사용자 수 17+1+2=20으로 맞춰 봤지만 11-04에 사용자 생성 시각을 다시 읽어 보니 그 설명은 뒷받침되지 않았습니다"
---

이전 기록에는 라이선스 사용이 18/25였는데, 다시 조회하니 20/25였습니다. 현재 20명 모두 라이선스를 가지고 있고, 처음에는 사용자 수를 날짜별로 나눈 17+1+2=20명으로 맞춰 "기록 이후 사용자가 늘어났다"고 추정했습니다. 그런데 2026-11-04에 사용자 생성 시각을 다시 읽어 보니 9~10월에 만들어진 사용자가 0명이어서 그 설명은 뒷받침되지 않았고, 차이의 원인은 아직 정하지 못했습니다.

## 요약

- 기록(18/25)과 조회(20/25)의 차이는 "기록 이후 사용자 2명 증가"라는 처음 추정을 11-04의 사용자 생성 시각 조회(9~10월 생성 0명)가 뒷받침하지 않음
- 값이 어긋나면 사용자 증감만 보지 말고 조회 날짜와 시각, 값을 읽은 화면·API를 같이 기록해 두면 됨
- 이전 기록 18/25의 시점과 원인은 확정하지 못했고, 현재 값 20/25(사용자 20명 모두 직접 할당)를 기준으로 삼음

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다.

---

## 전체 기록

### 1. 증상

- Microsoft 365 E5 Developer SKU V2가 20/25(남음 5)인데 이전 기록은 18/25였습니다.

![Microsoft 365 관리 센터 라이선스 화면. Microsoft 365 E5 Developer SKU V2가 20/25로 표시됨]({{ "/assets/images/2026/10/prework-licenses.png" | relative_url }})
*그림 1. 라이선스 화면 (빨간 상자: 할당 20/25, 계정 정보는 가림)*

### 2. 원인 및 분석

사용자 20명이 모두 라이선스를 가졌고(users=20, licensed=20), 날짜별로 10/14 이전 17명 + 10/14 1명 = 18명, 10/16 2명이 더해져 20명입니다.

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

#### 확인한 순서

1. 지금 값이 맞는가 → 관리 센터 화면과 `subscribedSkus` Graph 조회(구매 25 / 사용 20)가 일치
2. 사용자 수가 기록 이후 바뀌었는가 → 사용자 20명을 날짜별로 나눠 봄
3. 20명이 모두 라이선스를 갖는가 → 전체 사용자의 `assignedLicenses`를 셈

#### 날짜별 사용자 수

날짜별 내역은 아래와 같습니다(조회). 집계 기준 속성은 기록해 두지 않았습니다.

| 구분 | 인원 |
|---|---|
| 10/14 이전 | 17명 |
| 10/14 | 1명 |
| 10/16 | 2명 |
| 합계 | **20명** |

#### 라이선스 보유 수

전체 사용자의 라이선스 보유 수는 아래 스크립트로 확인했습니다(준비 코드 3줄: 토큰, `$h`, `$B`를 먼저 실행). users=20, licensed=20으로 사용자 20명이 모두 라이선스를 갖고 있었고, 할당 상태는 모두 Active(20건)에 전부 직접 할당(direct 20)이었습니다.

```powershell
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$u = (Invoke-RestMethod -Headers $h -Uri "$B/users?`$select=id,assignedLicenses,licenseAssignmentStates&`$top=999").value
"users=$($u.Count) licensed=$(($u | Where-Object { $_.assignedLicenses.Count -gt 0 }).Count)"
$u.licenseAssignmentStates | Group-Object state | ForEach-Object { "state=$($_.Name) count=$($_.Count)" }
$u.licenseAssignmentStates | Group-Object { if ($_.assignedByGroup) {'group'} else {'direct'} } | ForEach-Object { "assigned=$($_.Name) count=$($_.Count)" }
```

![라이선스 사용 수 확인]({{ "/assets/images/2026/10/m11-7-license-check.png" | relative_url }})
*그림 2. Cloud Shell 출력(위쪽은 실행한 명령). users=20, licensed=20으로 사용자 20명이 모두 라이선스를 갖고 있고, 라이선스 할당 상태는 모두 Active(20건)이며 **전부 직접 할당(direct 20)**입니다. 동적 그룹으로 겹쳐 들어왔던 그룹 할당은 원복 때 회수되어 지금은 없습니다. 계정 부분은 가렸습니다.*

이전 기록이 18/25였던 시점은 날짜별 합산으로 추정한 것이었습니다. 이 추정을 다시 확인하려고 2026-11-04에 Graph 탐색기에서 사용자 생성 시각을 조회했습니다.

- `GET /v1.0/users?$filter=createdDateTime ge 2026-09-01T00:00:00Z and createdDateTime le 2026-11-01T00:00:00Z&$select=createdDateTime`: 200 OK, 결과 `value`가 빈 배열(그림 3)
- 같은 방식으로 `createdDateTime ge 2026-10-01`을 조회했을 때 처음 보인 항목은 2026-11-02T15:03:11Z였습니다(하이브리드 실습용 계정으로 보이며 이 글의 20명 집계와는 별개이고, 이 조회는 목록을 끝까지 읽지 않았습니다).

즉 9~10월에 만들어진 사용자가 없으므로 "10/14에 1명, 10/16에 2명 추가"라는 날짜별 합산은 생성 시각과 맞지 않습니다. 그 합산이 어떤 날짜(예: 라이선스 할당일)를 기준으로 했는지는 기록이 남아 있지 않아 이 글에서는 더 따지지 못했습니다.

![Graph 탐색기에서 9~10월 생성 사용자 조회 결과가 빈 목록인 화면]({{ "/assets/images/2026/10/m02-3-users-created-sepoct-1104.png" | relative_url }})

*그림 3. 2026-11-04 Graph 탐색기. 2026-09-01~2026-11-01에 생성된 사용자를 조회한 결과(200 OK, `value`가 빈 배열).*

</details>

### 3. 결론

현재 값은 사용 20/25(사용자 20명 모두 직접 할당)입니다. 처음에는 "기록 이후 10/16에 사용자 2명 추가 → 사용 18 → 20"으로 추정했지만, 11-04에 읽은 사용자 생성 시각(9~10월 생성 0명)과 맞지 않아 그 설명은 확정하지 못한 추정으로만 남깁니다. 이전 기록 18/25가 어느 시점·어떤 화면의 값이었는지는 모르므로 현재 값 20/25를 기준으로 삼았습니다.

### 4. 권고방안

1. 라이선스 수 같은 값은 조회 날짜와 시각을 같이 기록합니다.
2. 어긋나면 사용자 생성·삭제와 라이선스 할당의 날짜를 각각 읽어 맞춰 보되, 맞지 않으면 억지로 설명하지 않고 현재 값을 기준으로 삼습니다.
3. 사용자를 늘리기 전에 남은 좌석을 확인합니다(이번에는 그룹 라이선스 실습용으로 5개를 남기려고 사용자 생성 안 함).

관련 글: [사전작업: 환경 점검]({{ "/m365/prework/" | relative_url }}) · [직접 라이선스와 그룹 라이선스가 겹침]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **문서**: 개발자 샌드박스(E5, 25개, 개발 활동이 있으면 자동 갱신)
    - 출처: [Developer Program 시작하기](https://learn.microsoft.com/office/developer-program/microsoft-365-developer-program-get-started), [FAQ](https://learn.microsoft.com/office/developer-program/microsoft-365-developer-program-faq)
- **조회**: 구매 25 / 사용 20 / 남음 5, 상태 Enabled
    - 출처: 관리 센터 + Graph `subscribedSkus`
- **조회**: 2026-09-01~2026-11-01에 생성된 사용자 0명(2026-11-04), 이후 첫 항목은 2026-11-02T15:03:11Z
    - 출처: Graph 탐색기, 그림 3
- **조회**: users=20 licensed=20, 할당 상태 Active 20건, 전부 직접(direct 20)
    - 출처: Cloud Shell(Graph)
- **추정(뒷받침되지 않음)**: 처음의 날짜별 합산(10/14 이전 17명 + 10/14 1명 + 10/16 2명 = 20명)과 "이전 기록 18/25는 10/14~15 시점 값"
    - 출처: 날짜별 합산, 11-04 생성 시각 조회와 맞지 않음

</details>
