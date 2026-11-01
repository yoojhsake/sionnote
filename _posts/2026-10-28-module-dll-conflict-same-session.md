---
title: "[Troubleshooting] 같은 세션에서 Graph 다음 Exchange 모듈을 불러오면 DLL이 충돌함: 묶음마다 새 세션으로 분리"
date: 2026-10-28 18:20:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 9
tags: [Troubleshooting, PowerShell, Microsoft Graph 모듈, ExchangeOnlineManagement, DLL 충돌, 새 세션]
excerpt: "Graph 다음 Exchange 모듈을 같은 창에서 불러오면 DLL 충돌. 묶음마다 새 pwsh 세션을 열자 5개 묶음 모두 충돌 0건이었습니다"
toc: true
---

Graph 스크립트를 돌린 창에서 이어서 Exchange 스크립트를 실행하자 `Could not load file or assembly … 0x80131040` 오류가 났습니다. 한 세션에는 같은 라이브러리의 한 버전만 올라가기 때문이라, 서비스 묶음마다 새 `pwsh` 세션을 열자 DLL 충돌이 0건이 되었습니다.

## 요약

- Graph 스크립트를 돌린 창에서 Exchange 스크립트를 실행하면 `Could not load file or assembly … 0x80131040` 계열 오류(Microsoft.IdentityModel.Abstractions)
- 서비스 모듈들이 같은 라이브러리의 다른 버전을 쓰는데 한 세션에는 한 버전만 올라감. 문서에 근거한 판단이고 충돌 DLL 버전 비교는 안 함
- 서비스 묶음마다 `pwsh -NoProfile`로 새 세션을 열어 실행
- 5개 묶음 실행 기록에 DLL 충돌 오류 0건(조회)
- 오류가 항목마다 나는지, 두 번째 서비스부터 전부 나는지부터 나눠 보면 구분됨

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

여러 서비스(Graph, Azure, Teams, Exchange, SharePoint)를 한 번에 읽는 스크립트 묶음을 한 창에서 차례로 실행했습니다. 그러면 Exchange 모듈을 불러오는 시점에 어셈블리를 불러올 수 없다는 오류가 났습니다.

Cloud Shell에서 같은 묶음을 시험했을 때도 같은 오류가 먼저 확인되어, PC 실행에서는 처음부터 피하도록 설계했습니다.

### 2. 원인과 해결

서비스 모듈들은 같은 라이브러리(Microsoft.IdentityModel.Abstractions 등)의 서로 다른 버전을 씁니다. 그런데 한 세션에는 한 버전만 올라가므로, 먼저 올라온 버전과 뒤 모듈이 원하는 버전이 다르면 충돌합니다.

해결은 간단했습니다. 서비스 묶음마다 `pwsh -NoProfile -File <묶음 실행 파일>`로 별도 프로세스를 열어 실행합니다. 설정 변경은 없고 실행 방식만 바꿨으니 원복할 것도 없습니다. 이렇게 하면 한 묶음이 실패해도 다른 묶음에 영향이 없고, 실패한 묶음만 다시 돌리면 됩니다.

### 3. 여러 서비스를 한 번에 읽을 때

서로 다른 서비스 모듈을 한 세션에 섞지 않고, **서비스 하나에 새 세션 하나**를 기본으로 합니다. 두 번째 서비스부터 어셈블리 오류가 나면 새 세션 분리부터 해 봅니다. 실행 기록에는 오류 문구를 남겨, 나중에 "충돌이 없었다"를 기록으로 말할 수 있게 합니다.

### 4. 확인 과정

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 관찰로 나누기

| 관찰 | 해석 |
|---|---|
| 첫 서비스는 되고, 두 번째 서비스에서 어셈블리 오류 | 세션에 먼저 올라온 라이브러리와 충돌 |
| 모든 항목이 처음부터 오류 | 충돌이 아니라 모듈 미설치나 접속 문제 |
| 새 창에서 같은 서비스만 실행하면 정상 | 충돌 확정 |

#### 해 본 것과 결과

1. 서비스 묶음 실행기를 만들어, 묶음마다 `pwsh -NoProfile -File <묶음 실행 파일>`로 별도 프로세스를 열었습니다. `-NoProfile`은 프로필에서 자동으로 불러오는 모듈이 섞이지 않게 하려는 것입니다.
2. 각 묶음은 시작할 때 대상 테넌트로 새로 접속하고, 접속한 테넌트가 맞는지 확인한 뒤 실행합니다. 묶음마다 실행 기록과 상태 파일을 남깁니다.
3. 같은 PC에서 Graph, Azure, Teams, Exchange·Purview 묶음을 차례로 실행했습니다(조회). 실행 기록의 경고 칸은 모두 비어 있었고 DLL 충돌 문구는 없었습니다.
    - SharePoint 묶음은 서비스 특성상 Windows PowerShell 5.1 창에서 따로 실행했습니다.

```text
Graph          완료 · 결과 11행
Azure          완료 · 결과 4행
Teams          완료 · 결과 8행
Exchange·Purview 완료 · 결과 4행
SharePoint(5.1) 완료 · 결과 10행
```

충돌의 정확한 원인 DLL 버전과 모듈 버전 조합은 비교해 보지 않았습니다. 이 부분은 확인 불가입니다.

- 시도: 오류 문구 확인과 새 세션 분리 효과 확인
- 막힌 이유: 분리로 해결되어 추가 분석을 하지 않음
- 다음 방법: 충돌 시 모듈 버전별 로드 결과 비교

</details>

### 5. 관련 글

- [회사 PC에서 모듈이 '정책에 막힘'으로 불러와지지 않을 때]({{ "/m365/troubleshooting/company-pc-module-blocked/" | relative_url }})
- [이미 접속된 세션을 재사용하는 스크립트가 다른 테넌트를 잴 수 있음]({{ "/m365/troubleshooting/script-reuses-existing-session/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: 어셈블리 로드 충돌 일반 설명
    - 출처: [about_Assemblies 관련 안내](https://learn.microsoft.com/powershell/scripting/dev-cross-plat/resolving-dependency-conflicts)
- **조회**: 5개 묶음 실행 결과, 충돌 오류 0건
    - 출처: 10/28 실행 기록
- **확인 불가**: 충돌 DLL 버전 비교
    - 시도: 분리 실행으로 회피. 막힌 이유: 회피로 해결됨. 다음 방법: 충돌 재현 시 버전 조합 비교

</details>
