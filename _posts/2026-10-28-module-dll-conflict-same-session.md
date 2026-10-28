---
title: "[Troubleshooting] 같은 세션에서 Graph 다음 Exchange 모듈을 불러오면 DLL이 충돌함 — 묶음마다 새 세션으로 분리"
date: 2026-10-28 18:20:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 9
tags: [Troubleshooting, PowerShell, Microsoft Graph 모듈, ExchangeOnlineManagement, DLL 충돌, 새 세션]
excerpt: "서비스별 스크립트를 한 창에서 이어 실행하면 어셈블리 충돌이 나는 문제를, 묶음마다 새 pwsh 세션을 열어 피한 기록"
toc: true
---

> 근거 표기: **조회** = 직접 실행해 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유·다음 방법 병기). 계정·테넌트 식별자는 적지 않았다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | Graph 스크립트를 실행한 같은 창에서 Exchange 스크립트를 실행하면 `Could not load file or assembly … 0x80131040` 계열 오류(Microsoft.IdentityModel.Abstractions) |
| 먼저 나눈 것 | 오류가 **항목마다** 나는가, 두 번째 서비스부터 **전부** 나는가 |
| 원인 | 서비스 모듈들이 같은 라이브러리의 서로 다른 버전을 쓰는데, 한 세션에는 한 버전만 올라감(문서에 근거한 판단, 충돌 DLL 버전 비교는 하지 않음) |
| 대처 | 서비스 묶음마다 `pwsh -NoProfile`로 **새 세션**을 열어 실행 |
| 결과 | **조회**: 5개 묶음 실행 기록에 DLL 충돌 오류 0건 |

---

## 전체 기록

### 1. 증상

여러 서비스(Graph, Azure, Teams, Exchange, SharePoint)를 한 번에 읽는 스크립트 묶음을 한 창에서 차례로 실행하면, Exchange 모듈을 불러오는 시점에 어셈블리를 불러올 수 없다는 오류가 났습니다. Cloud Shell에서 같은 묶음을 시험했을 때도 같은 오류가 먼저 확인되어, PC 실행에서는 처음부터 피하도록 설계했습니다.

### 2. 먼저 확인할 것

| 관찰 | 해석 |
|---|---|
| 첫 서비스는 되고, 두 번째 서비스에서 어셈블리 오류 | 세션에 먼저 올라온 라이브러리와 충돌 |
| 모든 항목이 처음부터 오류 | 충돌이 아니라 모듈 미설치·접속 문제 |
| 새 창에서 같은 서비스만 실행하면 정상 | 충돌 확정 |

### 3. 시도와 결과

1. 서비스 묶음 실행기를 만들어, 묶음마다 `pwsh -NoProfile -File <묶음 실행 파일>`로 별도 프로세스를 열었습니다. `-NoProfile`은 프로필에서 자동으로 불러오는 모듈이 섞이지 않게 하려는 것입니다.
2. 각 묶음은 시작할 때 대상 테넌트로 새로 접속하고 접속한 테넌트가 맞는지 확인한 뒤 실행하며, 묶음마다 실행 기록과 상태 파일을 남깁니다.
3. 결과(조회): 같은 PC에서 Graph, Azure, Teams, Exchange·Purview 묶음을 차례로 실행했고, 실행 기록의 경고 칸은 모두 비어 있었으며 DLL 충돌 문구는 없었습니다. SharePoint 묶음은 서비스 특성상 Windows PowerShell 5.1 창에서 따로 실행했습니다.

```text
Graph          완료 · 결과 11행
Azure          완료 · 결과 4행
Teams          완료 · 결과 8행
Exchange·Purview 완료 · 결과 4행
SharePoint(5.1) 완료 · 결과 10행
```

충돌의 정확한 원인 DLL 버전과 모듈 버전 조합은 비교해 보지 않았습니다. 이 부분은 확인 불가(시도: 오류 문구 확인과 새 세션 분리 효과 확인 / 막힌 이유: 분리로 해결되어 추가 분석을 하지 않음 / 다음 방법: 충돌 시 모듈 버전별 로드 결과 비교).

### 4. 대처와 원복

- 설정 변경은 없습니다. 실행 방식만 바꿨습니다.
- 한 묶음이 실패해도 다른 묶음에 영향이 없고, 실패한 묶음만 다시 실행하면 됩니다.

### 5. 운영에서는 이렇게 판단한다

1. 서로 다른 서비스 모듈을 한 세션에 섞지 않습니다. **서비스 하나 = 새 세션 하나**를 기본으로 합니다.
2. 두 번째 서비스부터 어셈블리 오류가 나면 새 세션 분리를 먼저 시도합니다.
3. 실행 기록에 오류 문구를 남겨, 나중에 "충돌이 없었다"를 기록으로 말할 수 있게 합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 어셈블리 로드 충돌 일반 설명 | [about_Assemblies 관련 안내](https://learn.microsoft.com/powershell/scripting/dev-cross-plat/resolving-dependency-conflicts) |
| 조회 | 5개 묶음 실행 결과, 충돌 오류 0건 | 10/28 실행 기록 |
| 확인 불가 | 충돌 DLL 버전 비교 | 시도: 분리 실행으로 회피. 막힌 이유: 회피로 해결됨. 다음 방법: 충돌 재현 시 버전 조합 비교 |

관련 글: [회사 PC에서 모듈이 '정책에 막힘'으로 불러와지지 않을 때]({{ "/m365/troubleshooting/company-pc-module-blocked/" | relative_url }}), [이미 접속된 세션을 재사용하는 스크립트가 다른 테넌트를 잴 수 있음]({{ "/m365/troubleshooting/script-reuses-existing-session/" | relative_url }})
