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

PC에서 Graph 스크립트를 돌린 창에서 이어서 Exchange 스크립트를 실행하자 `Could not load file or assembly … 0x80131040` 오류가 났습니다. 한 세션에는 같은 라이브러리의 한 버전만 올라가기 때문이라, 서비스 묶음마다 새 `pwsh` 세션을 열자 DLL 충돌이 0건이 되었습니다.

## 요약

- 서비스 모듈들이 같은 라이브러리의 다른 버전을 써서 한 세션에서 충돌함
- 두 번째 서비스부터 어셈블리 오류가 나면 서비스마다 새 세션을 열면 됨
- 충돌한 DLL과 모듈 버전 조합은 비교하지 않음(분리로 해결되어 시도하지 않음)

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다.

---

## 전체 기록

### 1. 증상

- 한 창에서 서비스 묶음을 이어 실행하면 Exchange 모듈 로드 때 어셈블리 오류

### 2. 원인 및 분석

문서에 따르면 PowerShell은 모든 어셈블리를 같은 Assembly Load Context에 올리므로, 서로 다른 모듈이 같은 어셈블리의 다른 버전을 요구하면 한 세션에서 충돌할 수 있습니다([Resolving PowerShell module assembly dependency conflicts](https://learn.microsoft.com/powershell/scripting/dev-cross-plat/resolving-dependency-conflicts)). 이번 오류가 어떤 DLL 때문인지는 비교하지 않았습니다(분리로 해결되어 시도하지 않음). 분리 후 5개 묶음 모두 경고 0건입니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

증상은 PC의 한 창에서 나온 것(작성자 관찰, 캡처 없음)이며, Cloud Shell 재현 여부는 이 글에서 기록하지 않았습니다. PC 실행은 처음부터 묶음을 분리하도록 설계했습니다.

#### 관찰로 나누기

| 관찰 | 해석 |
|---|---|
| 첫 서비스는 되고, 두 번째 서비스에서 어셈블리 오류 | 세션에 먼저 올라온 라이브러리와 충돌 |
| 모든 항목이 처음부터 오류 | 충돌이 아니라 모듈 미설치나 접속 문제 |
| 새 창에서 같은 서비스만 실행하면 정상 | 충돌일 가능성이 높음 |

#### 해 본 것과 결과

1. 서비스 묶음 실행기를 만들어, 묶음마다 `pwsh -NoProfile -File <묶음 실행 파일>`로 별도 프로세스를 열었습니다. `-NoProfile`은 프로필에서 자동으로 불러오는 모듈이 섞이지 않게 하려는 것입니다. 설정 변경은 없어 원복할 것이 없습니다.
2. 각 묶음은 시작할 때 대상 테넌트로 새로 접속하고, 접속한 테넌트가 맞는지 확인한 뒤 실행합니다. 묶음마다 실행 기록과 상태 파일을 남깁니다.
3. 같은 PC에서 Graph, Azure, Teams, Exchange·Purview 묶음을 차례로 실행했습니다(조회). 실행 기록의 경고 칸은 모두 비어 있었고 DLL 충돌 문구는 없었습니다.
    - SharePoint 묶음은 Windows PowerShell 5.1 창에서 따로 실행했습니다(이 PC에서의 실행 방식이며, PowerShell 7에서 `-UseWindowsPowerShell`로 쓰는 방법도 문서에 있음).

```text
Graph          완료 · 결과 11행
Azure          완료 · 결과 4행
Teams          완료 · 결과 8행
Exchange·Purview 완료 · 결과 4행
SharePoint(5.1) 완료 · 결과 10행
```

</details>

### 3. 결론

`라이브러리 버전 불일치 → Exchange 모듈 로드 실패 → 0x80131040`

충돌 DLL·모듈 버전 조합은 비교하지 않았습니다(분리로 해결되어 시도하지 않음. 재현 시 비교).

### 4. 권고방안

1. 조치: 묶음마다 `pwsh -NoProfile -File <묶음 실행 파일>`로 새 세션 실행(실패 묶음만 재실행)
2. 확인: 실행 기록(오류 문구 보존)에 `Could not load file or assembly`가 없으면 해결
3. 하지 말 것: 다른 서비스 모듈을 한 세션에 섞기.

관련 글: [회사 PC에서 모듈이 '정책에 막힘'으로 불러와지지 않을 때]({{ "/m365/troubleshooting/company-pc-module-blocked/" | relative_url }}) · [이미 접속된 세션을 재사용하는 스크립트가 다른 테넌트를 잴 수 있음]({{ "/m365/troubleshooting/script-reuses-existing-session/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: 어셈블리 로드 충돌 일반 설명
    - 출처: [Resolving PowerShell module assembly dependency conflicts](https://learn.microsoft.com/powershell/scripting/dev-cross-plat/resolving-dependency-conflicts). 문서는 해결책으로 `pwsh`를 하위 프로세스로 띄우는 방식도 제시함
- **조회**: 5개 묶음 실행 결과, 충돌 오류 0건
    - 출처: 10/28 실행 기록
- **시도하지 않은 항목**: 충돌 DLL 버전 비교
    - 시도: 분리 실행으로 회피. 시도하지 않은 이유: 회피로 해결됨. 다음 방법: 충돌 재현 시 버전 조합 비교

</details>
