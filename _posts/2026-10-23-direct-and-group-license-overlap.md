---
title: "[Troubleshooting] 직접 라이선스와 그룹 라이선스가 겹쳤을 때 어떻게 보이는가"
date: 2026-10-23 11:00:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 4
tags: [Troubleshooting, 그룹 라이선스, 직접 할당, 동적 그룹, licenseAssignmentStates]
excerpt: "직접 E5 사용자가 E5 동적 그룹에 들어가도 충돌은 없었습니다. 2건 모두 Active, 원복 후 그룹 할당만 회수, 사용 수는 가입 전과 원복 후 20/25(겹친 동안 값은 미기록)."
---

이미 직접 E5를 가진 시험 사용자 2가 같은 E5를 주는 동적 그룹에 들어가면, 같은 제품이 두 경로로 걸립니다. 겹친 동안 2건 모두 Active로 충돌이 없었고, 원복하자 그룹 할당만 회수되어 사용 수는 20/25 그대로였습니다(겹친 동안 값은 기록하지 못했고 가입 전과 원복 후만 같았습니다).

## 요약

- 직접 할당과 그룹 할당은 별개 경로로 기록되어 서로 덮지 않음
- 그룹으로 옮길 때는 그룹 반영을 확인한 뒤 직접 할당을 제거하면 됨
- 중복일 때 어느 쪽을 정리할지 운영 기준은 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 테넌트 ID, 도메인, 계정, 사용자 이름 등은 가렸습니다. 시험 사용자는 "시험 사용자 2"처럼 적었습니다.

---

## 전체 기록

### 1. 증상

- 동적 그룹 DG-Practice-02(규칙 `user.department -eq "Practice02"`)에 E5를 할당했는데, 시험 사용자 2는 이미 직접 E5를 갖고 있어 부서를 바꾸면 두 경로로 걸리는 상태가 어떻게 보일지 알 수 없었습니다.

### 2. 원인 및 분석

문서는 사용자를 그룹 사이에서 옮길 때 "먼저 추가, 나중에 제거"를 권합니다(문서: Manage group licenses). 직접 할당과 그룹 할당은 `licenseAssignmentStates`에 별개 경로(`assignedByGroup`)로 기록되어 서로 덮지 않습니다.

- 가입 전 직접 1건, 20 / 25 → 겹친 동안 2건 모두 Active → 원복 후(감사 로그 2026-10-23 10:12) 직접만, 20 / 25

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

**확인한 순서**

1. 사용자에게 같은 SKU가 몇 건, 어떤 경로로 걸려 있는가 → `licenseAssignmentStates`의 `assignedByGroup` 유무와 `state`
2. SKU 사용 수가 겹침 때문에 늘어나는가 → `subscribedSkus` 또는 관리 센터 20/25
3. 그룹에서 빠질 때 직접 할당이 영향을 받는가 → 원복 후 직접 할당 유지 여부

**처음 실습에서는 겹친 동안을 읽지 못했습니다.** 처음 실습(2026-10-22 09:29~09:33)에서는 부서를 Practice02로 바꾼 뒤 그룹 구성원 수만 읽었고, 사용자 쪽 라이선스 경로는 기록하지 못했습니다.

부서를 되돌려 그룹에서 빠진 뒤에야 확인했습니다. 그룹 쪽 할당이 사라지고 **직접 할당만 남았으며** 사용 수가 20/25로 돌아와 있었습니다(조회). 원복 후의 직접 할당 유지, `assignedByGroup` 비어 있음, SKU 20/25만 읽은 셈입니다.

![원복 후 사용자 라이선스 화면. E5 제품 하나, 상태 Active]({{ "/assets/images/2026/10/d2-user-license-after.png" | relative_url }})
*그림 1. 원복 후 시험 사용자 2의 라이선스 화면 (빨간 상자: 제품과 상태, 이름과 계정은 가림)*

**그래서 같은 실험을 다시 하며 겹친 동안을 읽었습니다.** 부서를 다시 바꿔 그룹에 가입시키자 같은 SKU에 직접 할당과 그룹 할당 2건이 모두 Active로 표시됐고 충돌은 없었습니다(조회). 부서를 원복하자(감사 로그 2026-10-23 10:12) 그룹 할당만 회수되고 직접 할당은 유지됐으며 사용 수는 20/25 그대로였습니다(겹친 동안 값은 기록하지 못했고 가입 전과 원복 후만 같았습니다).

단계별로 사용자의 라이선스 경로와 SKU 사용 수를 적으면 이렇습니다.

- 그룹 가입 전: 직접 1건, 20 / 25
- 그룹에 들어간 동안: 같은 SKU 2건(직접, 그룹) 모두 Active, 충돌 없음
    - SKU 사용 수: 겹친 동안의 값은 따로 기록하지 못함
- 부서 원복 후: 직접만 유지, `assignedByGroup` 비어 있음, 상태 Active, 20 / 25

원복 후 전체 사용자도 읽었습니다. 사용자 20명이 모두 라이선스를 갖고 있고, 할당 상태는 모두 Active 20건이며 **전부 직접 할당(direct 20)** 입니다. 시험 중 동적 그룹으로 겹쳐 들어왔던 그룹 할당은 원복 때 회수되어 지금은 없습니다.

![라이선스 사용 수 확인]({{ "/assets/images/2026/10/m11-7-license-check.png" | relative_url }})
*그림 2. Cloud Shell 출력(위쪽은 실행한 명령). users=20, licensed=20으로 사용자 20명이 모두 라이선스를 갖고 있고, 라이선스 할당 상태는 모두 Active(20건)이며 **전부 직접 할당(direct 20)**입니다. 동적 그룹으로 겹쳐 들어왔던 그룹 할당은 원복 때 회수되어 지금은 없습니다. 계정 부분은 가렸습니다.*

**실행한 스크립트** (준비 코드 3줄: 토큰, `$h`, `$B`를 먼저 실행)

```powershell
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$u = (Invoke-RestMethod -Headers $h -Uri "$B/users?`$select=id,assignedLicenses,licenseAssignmentStates&`$top=999").value
"users=$($u.Count) licensed=$(($u | Where-Object { $_.assignedLicenses.Count -gt 0 }).Count)"
$u.licenseAssignmentStates | Group-Object state | ForEach-Object { "state=$($_.Name) count=$($_.Count)" }
$u.licenseAssignmentStates | Group-Object { if ($_.assignedByGroup) {'group'} else {'direct'} } | ForEach-Object { "assigned=$($_.Name) count=$($_.Count)" }
```

</details>

### 3. 결론

직접 E5 + 그룹 E5 → 별개 경로로 기록, 충돌 없음 → 원복 시 그룹 할당만 회수

원복(부서를 빈 값으로 저장)은 완료했고, 이 테넌트의 같은 SKU 기준 값입니다. 중복일 때 운영 기준으로 어느 쪽을 정리할지는 확인 불가입니다(동작은 확인했지만 팀 기준이 없음, 다음 방법은 팀 기준 확인).

### 4. 권고방안

1. 조치: 직접 할당을 그룹으로 옮길 때는 먼저 그룹에 할당합니다.
2. 확인: 그룹 할당이 Active로 반영된 것을 본 뒤 직접 할당을 제거합니다.
3. 정리: DG-Practice-02는 그룹 라이선스를 먼저 제거해야 삭제할 수 있어 정리 항목으로 남겼습니다.

관련 글: [Identity 구조: 동적 그룹과 그룹 라이선스]({{ "/m365/d2-identity-groups/" | relative_url }}) · [그룹 라이선스를 Entra에서 할당할 수 없음]({{ "/m365/troubleshooting/license-assignment-not-in-entra/" | relative_url }}) · [라이선스 사용 수가 기록과 다름]({{ "/m365/troubleshooting/license-seat-count-mismatch/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: 그룹 기반 라이선스 관리, 사용자를 그룹 사이에서 옮길 때 "먼저 추가, 나중에 제거"
    - [Manage group licenses](https://learn.microsoft.com/microsoft-365/admin/manage/manage-group-licenses)
- 조회: 겹친 동안 같은 SKU에 직접 + 그룹 2건 모두 Active, 원복 후 그룹 할당만 회수, 사용 20/25 유지
    - 출처: Entra 사용자 라이선스 화면, 감사 로그
- 조회: users=20 licensed=20, 할당 상태 Active 20건, 전부 직접(direct 20)
    - 출처: Cloud Shell(Graph)
- 확인 불가: 직접+그룹 중복의 운영 기준
    - 시도 방법과 사유는 3절 "결론"

</details>
