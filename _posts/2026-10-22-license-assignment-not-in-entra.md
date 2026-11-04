---
title: "[Troubleshooting] 그룹 라이선스를 Entra에서 할당할 수 없음"
date: 2026-10-22 09:27:00 +0900
categories: [m365, troubleshooting]
area: 라이선스·그룹
seq: 3
tags: [Troubleshooting, 그룹 라이선스, Entra, M365 관리 센터, 라이선스 할당]
excerpt: "Entra 그룹 라이선스 탭에 할당 버튼이 없습니다. M365 관리 센터에서 대상을 그룹으로 골라 할당하니 1건이 붙었습니다"
---

Entra 그룹의 라이선스 탭을 열었는데 할당 버튼은 없고 안내 문구만 있습니다. 그룹 라이선스 할당은 M365 관리 센터에서 하도록 되어 있어, 그곳에서 대상 유형을 그룹으로 골라 할당하자 Graph 조회로 그룹에 라이선스 1건이 확인됐습니다.

## 요약

- 할당 버튼이 없는 것은 오류가 아니라 정상 동작임
- 그룹 라이선스는 M365 관리 센터에서 관리한다고 운영 절차에 적어 둬야 함
- 할당하는 사람의 관리자 역할을 미리 보고 중첩 그룹은 대상으로 쓰지 않음

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 테넌트 ID, 도메인, 계정, 사용자 이름 등은 가렸습니다.

---

## 전체 기록

### 1. 증상

- Entra 관리 센터 > 그룹(동적 그룹 DG-Practice-02) > 라이선스 탭: "라이선스 할당 추가, 제거 또는 재처리는 M365 관리 센터 내에서만 사용할 수 있습니다"(조회)

![Entra 그룹 라이선스 탭. 관리 센터에서만 할당할 수 있다는 안내]({{ "/assets/images/2026/10/d2-group-license.png" | relative_url }})
*그림 1. Entra 그룹의 라이선스 탭 (빨간 상자: 관리 센터 이동 안내와 할당된 제품)*

### 2. 원인 및 분석

(가) 관리 센터에서 관리, Groups Administrator, License Administrator, User Administrator 중 하나 이상 필요, 중첩 그룹 미지원(문서). (나) 할당 후 Graph `GRP|state=On|lic=1`.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

먼저 확인할 것은 세 가지였습니다.

1. 안내 문구가 오류인가, 정상 동작인가: 정상 동작(위 (가)).
2. 할당에 필요한 역할이 있는가: 위 세 역할 중 하나 이상.
3. 그룹 구조가 지원되는가: 중첩 그룹은 불가.

시도와 결과는 다음과 같습니다.

- Entra 그룹 > 라이선스 탭에서 할당하려 하니 버튼이 없고 관리 센터 이동 안내만 표시됐습니다.
- M365 관리 센터에서 할당하자 "라이선스가 할당되고 있습니다" 메시지가 나왔습니다.
    - 경로: 청구 > 라이선스 > Microsoft 365 E5 Developer SKU V2(할당 전 20/25) > 라이선스 할당 > 그룹 DG-Practice-02 선택 > 할당
- Graph로 그룹을 조회하니 `GRP|state=On|lic=1`이었습니다.

확인에 쓴 스크립트(읽기):

```powershell
$B = 'https://graph.microsoft.com/v1.0'
$grp = ((Invoke-AzRestMethod -Uri "$B/groups?`$filter=displayName eq 'DG-Practice-02'&`$select=id,membershipRuleProcessingState,assignedLicenses").Content | ConvertFrom-Json).value[0]
"GRP|state=$($grp.membershipRuleProcessingState)|lic=$($grp.assignedLicenses.Count)"    # GRP|state=On|lic=1
```

</details>

### 3. 결론

`관리 센터 전용 기능 → Entra 탭에는 안내만 → 관리 센터 할당 후 lic=1`

그룹은 삭제하지 않고 정리 항목에 남겼습니다.

### 4. 권고방안

1. 조치: 라이선스 할당 패널에서 대상 유형을 그룹으로 고르고, 대상 그룹에는 사용자를 직접 넣습니다.
2. 조치 후 확인: "오류 및 문제" 탭에 항목이 없어야 하며, 있으면 재처리합니다(문서).
3. 하지 말아야 할 것: 그룹 라이선스를 제거하기 전에 그룹 삭제

관련 글: [Identity 구조: 동적 그룹과 그룹 라이선스]({{ "/m365/d2-identity-groups/" | relative_url }}) · [직접 라이선스와 그룹 라이선스가 겹침]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: [Manage group licenses](https://learn.microsoft.com/microsoft-365/admin/manage/manage-group-licenses)
    - 그룹 기반 라이선스를 관리 센터에서 관리, 필요 역할, 중첩 불가, 오류와 재처리
- **문서**: [Licensing PowerShell/Graph examples](https://learn.microsoft.com/entra/identity/users/licensing-powershell-graph-examples)
    - 그룹 라이선스를 관리 센터에서 관리한다는 설명과 PowerShell 예
- **조회**: Entra와 관리 센터 화면 + Graph
    - Entra 그룹 라이선스 탭의 안내 문구, 할당 메시지, 그룹 `lic=1`

</details>
