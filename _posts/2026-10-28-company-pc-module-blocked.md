---
title: "[Troubleshooting] 회사 PC에서 모듈이 '정책에 막힘'으로 불러와지지 않을 때: 위치와 PowerShell 버전을 나눠 점검"
date: 2026-10-28 18:00:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 8
tags: [Troubleshooting, PowerShell, 모듈, 소프트웨어 제한 정책, Install-Module, Windows PowerShell 5.1, PowerShell 7]
excerpt: "회사 PC에서 Import-Module이 정책에 막혔다. 모듈을 Program Files에 두니 PowerShell 7·5.1 모두 불러와졌다"
toc: true
---

`Install-Module`은 끝났는데 `Import-Module`이 "소프트웨어 제한 정책에 의해 차단"처럼 실패하는 회사 PC가 있습니다. 모듈 위치와 PowerShell 버전을 나눠 시험해 보니, 모듈이 Program Files에 있으면 7과 5.1 모두 4개 모듈을 불러와 5개 묶음을 전부 끝낼 수 있었습니다.

## 요약

- `Install-Module`은 끝났는데 `Import-Module`이 "소프트웨어 제한 정책에 의해 차단"처럼 실패. 설치 단계에서는 "authenticode signature is not valid"
- 사용자 폴더의 모듈(`.psm1`, `.ps1xml`)이 실행 정책에 막히는 PC가 있음. 막는 주체(그룹 정책인지 보안 기능인지)는 **확인 불가**
    - 먼저 나눈 것: (1) 모듈이 어디에 있는가(사용자 폴더 / Program Files), (2) 어느 PowerShell(7 / Windows PowerShell 5.1)에서 시험했는가
- 관리자 창에서 전체 사용자 위치(Program Files)에 설치하고, 모듈마다 두 PowerShell에서 불러오기를 시험한 뒤 되는 쪽으로 실행
- 모듈이 Program Files에 있던 PC에서는 7과 5.1 모두 4개 모듈 불러오기 성공, 5개 묶음 전부 완료(조회)

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법과 사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다. 조회 값은 이 PC와 테넌트에서 직접 실행해 읽었고, PC 이름도 적지 않았습니다.

---

## 전체 기록

### 1. 증상

모듈 설치 중 `authenticode signature … is not valid`(서명이 올바르지 않음) 오류가 나는 경우가 있었습니다. 설치된 모듈을 불러오려 하면 사용자 폴더(`Documents\WindowsPowerShell\Modules`)의 모듈이 정책 때문에 막히는 PC가 있었고, 서식 파일(`.ps1xml`)만 따로 막히기도 했습니다. 그런데 같은 날 다른 PC에서는 같은 모듈이 문제없이 불러와졌습니다.

### 2. 원인과 해결

사용자 폴더에 설치된 모듈이 실행 정책에 막히는 PC가 있습니다. 막는 주체는 확인하지 못했습니다(아래 확인 과정의 '막힌 PC').

해결은 모듈을 전체 사용자 위치(Program Files)에 설치하고, PowerShell 7과 5.1 중 불러오기가 되는 쪽으로 실행하는 것입니다. Program Files에 모듈이 있던 PC에서는 4개 모듈이 두 버전 모두에서 불러와졌습니다(조회).

테넌트 설정은 바꾸지 않았고, 바뀐 것은 PC의 모듈 설치 위치뿐입니다. 관리자 권한이 필요한 설치는 관리자 창에서 한 번만 하고, 이후 실행은 일반 창에서 합니다. 정책을 풀거나 우회하려 하지는 않았습니다. 회사 PC의 보안 설정을 바꾸는 일은 이 작업의 범위가 아닙니다.

### 3. 다음에 모듈이 막히면

모듈 문제는 **위치 → PowerShell 버전 → 오류 문구** 순서로 나눕니다. 사용자 폴더 설치가 막히면 전체 사용자 위치(Program Files)에 설치하고, 그래도 막히면 다른 PowerShell 버전으로 시험합니다.

둘 다 막히면 정책을 우회하지 말고 Cloud Shell 같은 다른 실행 환경을 씁니다. 다만 Cloud Shell은 서비스별로 접속이 안 되는 모듈이 있어서 가능한 범위를 먼저 확인해야 합니다. 막는 주체를 모를 때는 "정책 때문"이라고 단정하지 않고 "막힘, 주체 확인 불가"로 적습니다.

### 4. 확인 과정

"모듈이 없다"와 "있는데 막힌다"는 대처가 다릅니다. 그래서 아래 순서로 나눴습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>


- 어디에 설치됐나: `Get-Module -ListAvailable <모듈>`의 경로
    - 사용자 폴더면 정책에 막힐 수 있고, Program Files면 대체로 통과
- 어느 버전의 PowerShell인가: `$PSVersionTable.PSVersion`
    - 7과 5.1은 모듈 위치와 호환 규칙이 다름
- 막힘 메시지가 무엇인가: Import-Module 오류 문구
    - "인식되지 않음"=모듈 없음, "정책/서명"=막힘

**점검 스크립트로 모듈별 불러오기 시험.** 사용자 폴더 모듈을 빼고 Program Files의 원본만 두고, PowerShell 7과 5.1에서 각각 `Import-Module`을 시험했습니다(조회).

**막힌 PC.** 사용자 폴더와 키트 폴더에 복사한 모듈도 막혔습니다. 모듈 본체(`.psm1`), 서식 파일(`.ps1xml`), 모듈 시작 스크립트가 모두 막혔고 폴더를 바꿔도 같았습니다. 다만 **막는 주체는 확인하지 못했습니다**. 사용자가 확인해 보니 PC에 적용된 그룹 정책은 없었습니다. 남은 후보(Smart App Control, WDAC, AppLocker, 보안 프로그램)는 읽기 전용 진단 명령으로 확인할 예정이라 확인 불가로 둡니다.

**통과한 PC.** 전체 사용자 위치에 설치된 모듈로 시험한 결과는 이렇습니다(조회).

```text
Microsoft.Graph.Authentication   PS7: 성공 · PS5.1: 성공
Az.Accounts                      PS7: 성공 · PS5.1: 성공
MicrosoftTeams                   PS7: 성공 · PS5.1: 성공
ExchangeOnlineManagement         PS7: 성공 · PS5.1: 성공
SharePoint 모듈 16.0.27612.12000 (5.1) : 불러오기 성공
```

**막힌 PC에서의 대체 경로.** SharePoint 모듈은 Windows PowerShell 5.1에서는 사용자 폴더에 있어도 불러와졌습니다(조회). 나머지 모듈을 5.1로 대신 실행하는 방법은 문서상 지원 범위지만(문서), 막힌 PC에서 실제로 끝까지 돌려 보지는 못했습니다. 이 부분은 확인 불가입니다(시도: 5.1 대체 실행 준비 / 막힌 이유: 해당 PC로 재시험 전 / 다음 방법: 점검 로그 재수집).

</details>

### 5. 관련 글

[문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }}), [같은 세션에서 두 서비스 모듈을 불러오면 DLL이 충돌함]({{ "/m365/troubleshooting/module-dll-conflict-same-session/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: PowerShell 7과 Windows PowerShell 5.1의 모듈 호환, [about_PowerShell_Editions](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_powershell_editions)
- 문서: 실행 정책, [about_Execution_Policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- 조회: 두 PC의 모듈 불러오기 시험 결과 (출처: 10/28 점검 로그)
- 확인 불가: 막는 주체(그룹 정책 / Smart App Control / WDAC / AppLocker / 보안 프로그램)
    - 시도: 적용 정책 유무 확인(없음).
    - 막힌 이유: 진단 명령 결과 대기.
    - 다음 방법: 읽기 전용 진단 후 해당 기능 설정 확인

</details>
