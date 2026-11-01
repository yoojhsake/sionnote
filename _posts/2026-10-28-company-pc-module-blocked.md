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

- 사용자 폴더 모듈이 막혀도 Program Files에 두면 7과 5.1 모두 불러와짐
- 모듈 위치부터 보고, 막히면 전체 사용자 위치에 설치한 뒤 버전을 바꿔 시험함
- 적용된 그룹 정책은 없었고 실제로 막는 주체는 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 이 PC와 테넌트에서 직접 실행해 읽었고, PC 이름도 적지 않았습니다.

---

## 전체 기록

### 1. 증상

- 모듈 설치 중 `authenticode signature … is not valid`(서명이 올바르지 않음) 오류
- 사용자 폴더(`Documents\WindowsPowerShell\Modules`)의 모듈이 정책에 막힘, 서식 파일(`.ps1xml`)만 막히기도 함

### 2. 원인 및 분석

"없다"와 "있는데 막힌다"는 대처가 달라 위치 → 버전 → 오류 문구 순으로 봤습니다([about_Execution_Policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)).

같은 날 막힌 PC는 사용자 폴더 / 통과한 PC는 Program Files 모듈이었습니다(조회).

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

- 어디에 설치됐나: `Get-Module -ListAvailable <모듈>`의 경로
    - 사용자 폴더면 정책에 막힐 수 있고, Program Files면 대체로 통과
- 어느 버전의 PowerShell인가: `$PSVersionTable.PSVersion`
    - 7과 5.1은 모듈 위치와 호환 규칙이 다름
- 막힘 메시지가 무엇인가: Import-Module 오류 문구
    - "인식되지 않음"=모듈 없음, "정책/서명"=막힘

**점검 스크립트로 모듈별 불러오기 시험.** 사용자 폴더 모듈을 빼고 Program Files의 원본만 두고, PowerShell 7과 5.1에서 각각 `Import-Module`을 시험했습니다(조회).

**막힌 PC.** 사용자 폴더와 키트 폴더에 복사한 모듈도 막혔습니다. 모듈 본체(`.psm1`), 서식 파일(`.ps1xml`), 모듈 시작 스크립트가 모두 막혔고 폴더를 바꿔도 같았습니다. 사용자가 확인해 보니 PC에 적용된 그룹 정책은 없었습니다.

**통과한 PC.** 전체 사용자 위치에 설치된 모듈로 시험한 결과는 이렇습니다(조회).

```text
Microsoft.Graph.Authentication   PS7: 성공 · PS5.1: 성공
Az.Accounts                      PS7: 성공 · PS5.1: 성공
MicrosoftTeams                   PS7: 성공 · PS5.1: 성공
ExchangeOnlineManagement         PS7: 성공 · PS5.1: 성공
SharePoint 모듈 16.0.27612.12000 (5.1) : 불러오기 성공
```

**막힌 PC에서의 대체 경로.** SharePoint 모듈은 Windows PowerShell 5.1에서는 사용자 폴더에 있어도 불러와졌습니다(조회). 나머지 모듈을 5.1로 대신 실행하는 방법은 문서상 지원 범위입니다(문서).

</details>

### 3. 결론

`사용자 폴더 모듈 → 정책에 막힘 → Import-Module 실패`

바뀐 것은 PC의 모듈 설치 위치뿐입니다. 확인 불가:

- 막는 주체: 그룹 정책은 없음, 남은 후보(Smart App Control, WDAC, AppLocker, 보안 프로그램)는 읽기 전용 진단 예정
- 막힌 PC의 5.1 대체 실행: 시도 5.1 대체 실행 준비 / 막힌 이유 재시험 전 / 다음 방법 점검 로그 재수집

### 4. 권고방안

1. 조치: 모듈을 Program Files(전체 사용자 위치)에 설치하고 7과 5.1 중 되는 쪽으로 실행합니다. 설치는 관리자 창에서 한 번, 실행은 일반 창에서 합니다.
2. 조치 후 확인: `Import-Module`이 "정책/서명" 오류 없이 끝나면 됩니다. 둘 다 막히면 Cloud Shell을 쓰되 안 되는 모듈이 있어 범위를 먼저 봅니다.
3. 하지 말아야 할 것: 정책을 풀거나 우회하지 않습니다(회사 PC 보안 설정은 작업 범위 밖). 주체를 모르면 "막힘, 주체 확인 불가"로 적습니다.

관련 글: [문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }}) · [같은 세션에서 두 서비스 모듈을 불러오면 DLL이 충돌함]({{ "/m365/troubleshooting/module-dll-conflict-same-session/" | relative_url }})

### 근거 자료

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
