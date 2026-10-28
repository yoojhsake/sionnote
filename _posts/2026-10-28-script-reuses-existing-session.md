---
title: "[Troubleshooting] 이미 접속된 세션을 재사용하는 스크립트가 다른 테넌트를 잴 수 있음 — 테넌트 ID로 접속하고 확인한 뒤 실행"
date: 2026-10-28 18:40:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 10
tags: [Troubleshooting, PowerShell, 테넌트, Connect-MgGraph, Connect-AzAccount, Connect-MicrosoftTeams, 접속 확인]
excerpt: "다른 사람이 만든 조회 스크립트가 기존 접속을 그대로 쓸 때, 엉뚱한 테넌트 값이 결과에 섞이지 않도록 접속과 확인을 앞에 둔 기록"
toc: true
---

> 근거 표기: **조회** = 직접 실행해 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유·다음 방법 병기). 계정·테넌트 식별자는 적지 않았다.

## 요약

| 항목 | 내용 |
|---|---|
| 상황 | 받은 조회 스크립트가 "이미 접속된 세션이 있으면 그대로 쓴다" |
| 위험 | 이전에 다른 테넌트로 접속해 둔 창에서 실행하면 **다른 테넌트의 값**이 우리 결과로 기록됨 |
| 먼저 나눈 것 | 접속 코드가 스크립트 안에 있는가, 밖(실행하는 사람)에 있는가 |
| 대처 | 스크립트는 고치지 않고, 실행 앞단에서 대상 테넌트 ID로 새로 접속한 뒤 **접속한 테넌트 ID가 대상과 같을 때만** 실행 |
| 결과 | **조회**: Graph·Azure·Teams·Exchange 묶음에서 접속 테넌트가 대상과 일치함을 기록, SharePoint는 관리 주소로 확인 |

---

## 전체 기록

### 1. 상황

조회 스크립트 중 일부는 `Get-MgContext`·`Get-AzContext` 같은 명령으로 기존 접속이 있는지 보고, 있으면 다시 접속하지 않습니다. 같은 PC에서 여러 테넌트(예: 다른 사람의 시험 테넌트, 고객 테넌트)에 번갈아 접속하는 환경에서는, 이 동작 때문에 **어느 테넌트의 값인지 모른 채 결과가 저장**될 수 있습니다. 이번 작업에서 실제로 틀린 값이 기록된 일은 없었고, 위험을 미리 막은 사례입니다.

### 2. 먼저 확인할 것

| 확인 | 방법 |
|---|---|
| 스크립트가 접속을 직접 하는가 | 스크립트 앞부분의 `Connect-*` 호출 유무, 기존 접속 재사용 분기 |
| 지금 세션이 어느 테넌트인가 | `Get-MgContext`의 TenantId, `Get-AzContext`의 Tenant, `Get-CsTenant`의 TenantId |
| 결과 파일에 테넌트가 적히는가 | 결과 열에 테넌트 정보가 없으면 나중에 구별할 수 없음 |

### 3. 시도와 결과

1. 스크립트 원본은 수정하지 않았습니다. 받은 그대로 쓰는 것이 비교·재현에 유리하기 때문입니다.
2. 실행 앞단에서 **대상 테넌트 ID를 지정해 새로 접속**했습니다(`-TenantId` 사용).
3. 접속 직후 **접속한 테넌트 ID가 대상과 같은지 비교**하고, 다르면 스크립트를 실행하지 않고 중단하게 했습니다.
4. 서비스마다 확인 방법이 달라 각각 따로 처리했습니다.

| 서비스 | 확인 방법 | 결과(조회) |
|---|---|---|
| Graph | 접속 후 컨텍스트의 TenantId 비교 | 일치 |
| Azure | 컨텍스트의 Tenant ID 비교 | 일치 |
| Teams | `Get-CsTenant`의 TenantId 비교 | 일치 |
| Exchange·Purview | 접속 정보의 TenantID 비교(스크립트가 직접 접속) | 일치 |
| SharePoint | 관리 주소(`<테넌트>-admin`)가 대상인지 확인 | 주소 일치(테넌트 ID 비교는 하지 않음) |

SharePoint는 테넌트 ID가 아니라 주소로 확인했습니다. 주소에 테넌트 이름이 들어 있어 사실상 같은 효과지만, ID 비교와는 다른 확인입니다.

### 4. 대처와 원복

- 설정을 바꾸지 않았습니다.
- 실행 기록에 접속 계정과 테넌트 일치 여부를 함께 남겼습니다. 계정·ID는 이 글에 적지 않았습니다.

### 5. 운영에서는 이렇게 판단한다

1. 받은 스크립트는 **접속을 직접 하는지**부터 읽습니다.
2. 여러 테넌트를 오가는 PC라면 실행 전에 항상 대상 테넌트로 새로 접속하고, 접속한 테넌트를 눈으로·코드로 한 번 더 확인합니다.
3. 결과 파일에 대상 테넌트(또는 접속 주소)를 함께 남깁니다.
4. 읽기 전용 스크립트라도 "어느 테넌트의 값인가"가 틀리면 결과 전체를 쓸 수 없습니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | `Connect-MgGraph -TenantId` | [Connect-MgGraph](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/connect-mggraph) |
| 문서 | `Connect-AzAccount -Tenant` | [Connect-AzAccount](https://learn.microsoft.com/powershell/module/az.accounts/connect-azaccount) |
| 조회 | 묶음별 접속 테넌트 일치 기록 | 10/28 실행 기록 |
| 확인 불가 | 기존 접속이 남은 상태에서 실제로 틀린 값이 나오는 장면 | 시도: 의도적 재현은 하지 않음. 막힌 이유: 다른 테넌트 접속 시험은 범위 밖. 다음 방법: 시험 테넌트 2개로 재현 |

관련 글: [같은 세션에서 두 서비스 모듈을 불러오면 DLL이 충돌함]({{ "/m365/troubleshooting/module-dll-conflict-same-session/" | relative_url }})
