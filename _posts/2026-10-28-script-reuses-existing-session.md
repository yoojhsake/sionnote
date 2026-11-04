---
title: "[Troubleshooting] 이미 접속된 세션을 재사용하는 스크립트가 다른 테넌트를 잴 수 있음: 테넌트 ID로 접속하고 확인한 뒤 실행"
date: 2026-10-28 18:40:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 10
tags: [Troubleshooting, PowerShell, 테넌트, Connect-MgGraph, Connect-AzAccount, Connect-MicrosoftTeams, 접속 확인]
excerpt: "기존 세션을 재사용하는 스크립트는 다른 테넌트를 잴 수 있습니다. 테넌트 ID로 새로 접속해 일치를 확인한 뒤 실행했습니다."
toc: true
---

받은 조회 스크립트가 이미 접속된 세션을 그대로 쓰면, 이전에 다른 테넌트로 접속해 둔 창에서는 다른 테넌트의 값이 우리 결과로 기록될 수 있습니다. 스크립트는 고치지 않고, 대상 테넌트 ID로 새로 접속해 접속한 테넌트 ID가 같을 때만 실행했습니다.

## 요약

- 기존 세션을 재사용하는 스크립트는 실행 창 상태에 따라 다른 테넌트를 잼
- 받은 스크립트는 접속을 직접 하는지부터 읽고, 결과에 대상 테넌트를 남김
- SharePoint는 테넌트 ID가 아닌 관리 주소로만 확인했음

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다.

---

## 전체 기록

### 1. 증상

- 일부 스크립트는 `Get-MgContext`, `Get-AzContext`에 접속이 보이면 재접속하지 않습니다.
- 여러 테넌트를 오가는 PC에서는 어느 테넌트 값인지 모른 채 저장될 수 있습니다(이번엔 없음).

### 2. 원인 및 분석

접속을 "지금 열린 세션"에 맡기는 구조가 원인입니다. 대상 ID로 새로 접속하니 Graph, Azure, Teams, Exchange·Purview는 테넌트 ID가 일치했고, SharePoint는 관리 주소로만 확인했습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

(작성자의 PC 사용 환경 설명) 확인 대상 PC는 여러 테넌트에 번갈아 접속할 수 있는 환경입니다.

1. 스크립트가 접속을 직접 하는가: 스크립트 앞부분의 `Connect-*` 호출 유무, 기존 접속 재사용 분기를 봤습니다.
2. 지금 세션이 어느 테넌트인가: `Get-MgContext`의 TenantId, `Get-AzContext`의 Tenant, `Get-CsTenant`의 TenantId를 봤습니다.
3. 결과 파일에 테넌트가 적히는가: 결과 열에 테넌트 정보가 없으면 나중에 구별할 수 없습니다.

서비스별로 직접 실행해 확인한 값(조회)입니다.

| 서비스 | 확인 방법 | 결과(조회) |
|---|---|---|
| Graph | 접속 후 컨텍스트의 TenantId 비교 | 일치 |
| Azure | 컨텍스트의 Tenant ID 비교 | 일치 |
| Teams | `Get-CsTenant`의 TenantId 비교 | 일치 |
| Exchange·Purview | 접속 정보의 TenantID 비교(스크립트가 직접 접속) | 일치 |
| SharePoint | 관리 주소(`<테넌트>-admin`)가 대상인지 확인 | 주소 일치(ID 비교는 하지 않음) |

SharePoint는 주소에 테넌트 이름이 들어 있어 사실상 같은 효과지만, ID 비교와는 다른 확인입니다. 실행 기록에는 접속 계정과 테넌트 일치 여부를 남겼고, 계정과 ID는 이 글에 적지 않았습니다. 읽기 전용 스크립트라도 테넌트가 틀리면 결과 전체를 쓸 수 없습니다.

</details>

### 3. 결론

`기존 세션 재사용 → 창에 남은 다른 테넌트 접속 → 그 테넌트 값이 결과로 기록`

실제로 틀린 값이 나오는 장면은 시도하지 않았습니다(범위 밖이라 재현 안 함. 시험 테넌트 2개로 재현 가능).

### 4. 권고방안

1. 조치: 원본은 그대로 두고(비교·재현용) 실행 앞단에서 `Connect-MgGraph -TenantId`, `Connect-AzAccount -Tenant`처럼 대상을 지정해 새로 접속하고 테넌트 ID가 다르면 중단합니다.
2. 확인: 실행 기록에 테넌트 일치 여부, 결과 파일에 대상 테넌트(또는 접속 주소)를 남깁니다.
3. 하지 말 것: 접속 방식을 읽지 않고 남의 스크립트 실행하기

관련 글: [같은 세션에서 두 서비스 모듈을 불러오면 DLL이 충돌함]({{ "/m365/troubleshooting/module-dll-conflict-same-session/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- **문서**: `Connect-MgGraph -TenantId`, [Connect-MgGraph](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/connect-mggraph)
- **문서**: `Connect-AzAccount -Tenant`, [Connect-AzAccount](https://learn.microsoft.com/powershell/module/az.accounts/connect-azaccount)
- **조회**: 묶음별 접속 테넌트 일치 기록 (출처: 10/28 실행 기록)
- **시도하지 않은 항목**: 기존 접속이 남은 상태에서 실제로 틀린 값이 나오는 장면
    - 시도: 의도적 재현은 하지 않음.
    - 시도하지 않은 이유: 다른 테넌트 접속 시험은 범위 밖.
    - 다음 방법: 시험 테넌트 2개로 재현

</details>
