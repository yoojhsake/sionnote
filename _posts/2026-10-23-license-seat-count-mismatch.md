---
title: "[트러블슈팅] 라이선스 사용 수가 기록(18/25)과 조회(20/25)로 다르다"
date: 2026-10-23 11:00:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 6
tags: [트러블슈팅, 라이선스, 좌석 수, 사용자 수, 기록 대조]
excerpt: "기록상 18/25와 조회값 20/25가 달랐던 이유를 날짜별 사용자 수(17+1+2)로 맞춰 본 기록"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·막힌 이유·다음 방법 병기). 테넌트 ID·도메인·계정·사용자 이름은 게시하지 않았습니다.

## 요약

| 구분 | 내용 |
|---|---|
| 증상 | 이전 기록에는 라이선스 사용이 18/25인데 조회하니 20/25 |
| 원인 | 기록 이후에 사용자가 늘어난 것으로 보임: 10/14 이전 17명 + 10/14 1명 + 10/16 2명 = 20명 |
| 대처 | 사용자 수를 날짜별로 나눠 20명이 되는지 맞춰 보고, 전체 사용자의 라이선스 보유 수를 명령으로 확인 |
| 결과 | 20명이 모두 라이선스를 가짐. 이전 기록은 10/14~15 시점 값으로 보임 |

---

## 전체 기록

### 1. 증상

사전작업에서 라이선스 화면을 읽으니 Microsoft 365 E5 Developer SKU V2가 **20/25**(구매 25 / 사용 20 / 남음 5)였습니다. 그런데 이전에 남겨 둔 기록에는 **18/25**로 적혀 있었습니다(조회). 차이의 원인을 알 수 없었습니다.

![Microsoft 365 관리 센터 라이선스 화면. Microsoft 365 E5 Developer SKU V2가 20/25로 표시됨]({{ "/assets/images/2026/10/prework-licenses.png" | relative_url }})
*그림 1. 라이선스 화면 (빨간 상자: 할당 20/25, 계정 정보는 가림)*

### 2. 먼저 확인할 것

1. 지금 값이 맞는가 → 관리 센터 화면과 `subscribedSkus` Graph 조회(구매 25 / 사용 20)가 일치
2. 사용자 수가 기록 이후 바뀌었는가 → 사용자 20명을 날짜별로 나눠 봄
3. 20명이 모두 라이선스를 갖는가 → 전체 사용자의 `assignedLicenses`를 셈

### 3. 시도와 결과

날짜별 내역은 아래와 같습니다(조회).

| 구분 | 인원 |
|---|---|
| 10/14 이전 | 17명 |
| 10/14 | 1명 |
| 10/16 | 2명 |
| 합계 | **20명** |

이전 기록은 10/14~15 시점 값으로 보입니다. 10/14 이전 17명에 10/14의 1명을 더하면 18명이고, 10/16의 2명이 더해져 20명이 된다는 계산입니다.

전체 사용자의 라이선스 보유 수는 아래 스크립트로 확인했고(준비 코드 3줄: 토큰·`$h`·`$B`를 먼저 실행), users=20, licensed=20으로 사용자 20명이 모두 라이선스를 갖고 있었습니다. 할당 상태는 모두 Active(20건)이며 전부 직접 할당(direct 20)입니다.

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
*그림 2. Cloud Shell 출력(위쪽은 실행한 명령). users=20, licensed=20으로 사용자 20명이 모두 라이선스를 갖고 있고, 라이선스 할당 상태는 모두 Active(20건)이며 **전부 직접 할당(direct 20)**이다. 동적 그룹으로 겹쳐 들어왔던 그룹 할당은 원복 때 회수되어 지금은 없다. 계정 부분은 가렸다.*

이전 기록이 18/25였던 시점은 날짜별 합산으로 추정한 값이며, 10/14~15 시점으로 보인다는 것까지가 확인한 범위입니다.

### 4. 대처·원복

- 값은 바꾸지 않았습니다. 현재 조회값 20/25를 기준으로 삼았습니다.
- 좌석이 5개뿐이므로 직접 할당으로 사용자를 더 만들면 25/25가 됩니다. 그룹 라이선스 실습에 쓸 좌석을 위해 사용자 생성은 하지 않았습니다.

### 5. 운영에서는 이렇게 판단한다

- 라이선스 수 같은 값을 기록할 때는 **조회한 날짜와 시각**을 함께 적습니다. 값만 적으면 사용자가 늘거나 줄었을 때 기록과 조회가 어긋나 보입니다.
- 값이 어긋나면 틀린 쪽을 찾기 전에, 그 사이에 **사용자 생성·삭제가 있었는지**를 날짜별로 먼저 맞춰 봅니다.
- 좌석이 적은 환경에서는 사용자를 늘리기 전에 남은 좌석 수를 확인합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 개발자 샌드박스(E5, 25개, 개발 활동이 있으면 자동 갱신) | [Developer Program 시작하기](https://learn.microsoft.com/office/developer-program/microsoft-365-developer-program-get-started), [FAQ](https://learn.microsoft.com/office/developer-program/microsoft-365-developer-program-faq) |
| 조회 | 구매 25 / 사용 20 / 남음 5, 상태 Enabled | 관리 센터 + Graph `subscribedSkus` |
| 조회 | 10/14 이전 17명 + 10/14 1명 + 10/16 2명 = 20명 | 날짜별 사용자 수 |
| 조회 | users=20 licensed=20, 할당 상태 Active 20건, 전부 직접(direct 20) | Cloud Shell(Graph) |
| 추정 | 이전 기록 18/25는 10/14~15 시점 값으로 보임 | 날짜별 합산 |

관련 글: [사전작업 — 환경 점검]({{ "/m365/prework/" | relative_url }}), [직접 라이선스와 그룹 라이선스가 겹침]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})
