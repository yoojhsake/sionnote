---
title: "[트러블슈팅] 그룹 라이선스를 Entra에서 할당할 수 없다"
date: 2026-10-22 09:27:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 3
tags: [트러블슈팅, 그룹 라이선스, Entra, M365 관리 센터, 라이선스 할당]
excerpt: "Entra 그룹의 라이선스 탭에 할당 버튼이 없을 때 M365 관리 센터에서 그룹을 대상으로 할당하는 방법과 필요 역할·제약"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값. 테넌트 ID·도메인·계정·사용자 이름은 게시하지 않았습니다.

## 요약

| 구분 | 내용 |
|---|---|
| 증상 | Entra 그룹 > 라이선스 탭에 할당 버튼이 없고 안내 문구만 있음 |
| 원인 | 그룹 라이선스의 할당·제거·재처리는 M365 관리 센터에서 하도록 되어 있음(조회, 문서) |
| 대처 | M365 관리 센터 > 청구 > 라이선스 > 제품 > 라이선스 할당에서 대상 유형을 그룹으로 선택 |
| 결과 | "라이선스가 할당되고 있습니다" 메시지, Graph 조회로 그룹에 라이선스 1건(`lic=1`) 확인 |

---

## 전체 기록

### 1. 증상

동적 그룹 DG-Practice-02에 E5 라이선스를 주려고 Entra 관리 센터에서 그룹 > 라이선스 탭을 열었습니다. 할당 버튼은 없고 "라이선스 할당 추가, 제거 또는 재처리는 M365 관리 센터 내에서만 사용할 수 있습니다"라는 안내만 나왔습니다(조회).

![Entra 그룹 라이선스 탭. 관리 센터에서만 할당할 수 있다는 안내]({{ "/assets/images/2026/10/d2-group-license.png" | relative_url }})
*그림 1. Entra 그룹의 라이선스 탭 (빨간 상자: 관리 센터 이동 안내와 할당된 제품)*

### 2. 먼저 확인할 것

1. 안내 문구가 오류인가, 정상 동작인가 → 문구가 이동할 곳(M365 관리 센터)을 알려 주므로 정상 동작입니다. 문서에도 관리 센터에서 그룹 라이선스를 관리한다고 되어 있습니다.
2. 할당에 필요한 역할이 있는가 → 문서 기준 Groups Administrator, License Administrator, User Administrator 중 하나 이상이 필요합니다.
3. 그룹 구조가 지원되는가 → 중첩 그룹은 지원되지 않습니다(문서).

### 3. 시도와 결과

| 시도 | 결과 |
|---|---|
| Entra 그룹 > 라이선스 탭에서 할당 | 버튼 없음, 관리 센터 이동 안내만 표시 |
| M365 관리 센터 > 청구 > 라이선스 > Microsoft 365 E5 Developer SKU V2(할당 전 20/25) > 라이선스 할당 > 그룹 DG-Practice-02 선택 > 할당 | "라이선스가 할당되고 있습니다" 메시지 |
| Graph로 그룹 조회 | `GRP|state=On|lic=1` |

확인에 쓴 스크립트(읽기):

```powershell
$B = 'https://graph.microsoft.com/v1.0'
$grp = ((Invoke-AzRestMethod -Uri "$B/groups?`$filter=displayName eq 'DG-Practice-02'&`$select=id,membershipRuleProcessingState,assignedLicenses").Content | ConvertFrom-Json).value[0]
"GRP|state=$($grp.membershipRuleProcessingState)|lic=$($grp.assignedLicenses.Count)"    # GRP|state=On|lic=1
```

### 4. 대처·원복

- 할당은 관리 센터의 라이선스 할당 패널에서 대상 유형을 그룹으로 골라 진행합니다.
- 오류가 나면 "오류 및 문제" 탭에서 확인하고 재처리합니다(문서).
- 원복: 그룹을 정리할 때는 **그룹 라이선스를 먼저 제거한 뒤 그룹을 삭제**합니다. 삭제는 하지 않았고 정리 항목으로 남겼습니다.

### 5. 운영에서는 이렇게 판단한다

- 그룹 라이선스는 Entra가 아니라 **M365 관리 센터에서 관리**한다고 운영 절차에 적어 둡니다.
- 할당 권한은 Groups Administrator, License Administrator, User Administrator 중 하나가 필요합니다(문서). 할당하는 사람이 어느 역할을 갖는지 미리 확인합니다.
- 중첩 그룹은 지원되지 않으므로 라이선스 대상 그룹은 사용자를 직접 구성원으로 갖게 설계합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 그룹 기반 라이선스를 관리 센터에서 관리, 필요 역할, 중첩 불가, 오류·재처리 | [Manage group licenses](https://learn.microsoft.com/microsoft-365/admin/manage/manage-group-licenses) |
| 문서 | 그룹 라이선스를 관리 센터에서 관리한다는 설명과 PowerShell 예 | [Licensing PowerShell/Graph examples](https://learn.microsoft.com/entra/identity/users/licensing-powershell-graph-examples) |
| 조회 | Entra 그룹 라이선스 탭의 안내 문구, 할당 메시지, 그룹 `lic=1` | Entra·관리 센터 화면 + Graph |

관련 글: [Identity 구조 — 동적 그룹과 그룹 라이선스]({{ "/m365/d2-identity-groups/" | relative_url }}), [직접 라이선스와 그룹 라이선스가 겹침]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})
