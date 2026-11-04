---
title: "[Troubleshooting] 회사 PC에서 모듈이 '정책에 막힘'으로 불러와지지 않을 때: 위치와 PowerShell 버전을 나눠 점검"
date: 2026-10-28 18:00:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 8
tags: [Troubleshooting, PowerShell, 모듈, 소프트웨어 제한 정책, AppLocker, Install-Module, Windows PowerShell 5.1, PowerShell 7]
excerpt: "회사 PC 한 대에서는 사용자 폴더 모듈의 Import-Module이 정책에 막혔고, 다른 PC에서는 Program Files의 모듈이 PowerShell 7·5.1 모두 불러와졌다. 실습 VM에서는 AppLocker 스크립트 규칙으로 같은 증상(사용자 폴더 차단, Program Files 통과)을 재현했지만 회사 PC의 막는 주체가 AppLocker였는지는 확인하지 못했다"
toc: true
---

`Install-Module`은 끝났는데 `Import-Module`이 "소프트웨어 제한 정책에 의해 차단"처럼 실패하는 회사 PC가 있습니다. 모듈 위치와 PowerShell 버전을 나눠 시험해 보았습니다. 막힌 PC와 통과한 PC는 서로 다른 PC입니다. 통과한 PC에서는 모듈이 Program Files에 있었고 7과 5.1 모두 4개 모듈을 불러와 5개 묶음을 끝낼 수 있었습니다. 이후 2026-11-04에 Hyper-V 실습 VM에서 AppLocker 스크립트 기본 규칙만 적용해 같은 증상(사용자 폴더 모듈 차단, Program Files 모듈 통과)을 재현했고, 원인 확인 명령과 허용 방법까지 시험했습니다. 다만 회사 PC를 막은 주체가 AppLocker였는지는 이 시험으로 확인되지 않았습니다.

## 요약

- 막힌 PC에서는 사용자 폴더 모듈이 막혔고, 다른 PC에서는 Program Files 모듈이 7과 5.1 모두 불러와짐(같은 PC에서 위치만 바꿔 비교한 것은 아님)
- 모듈 위치부터 보고, 막히면 전체 사용자 위치에 설치한 뒤 버전을 바꿔 시험하는 순서를 권함(막힌 PC에서 Program Files 설치는 시험하지 않음)
- 그룹 정책은 없다고 사용자가 확인했고, 회사 PC를 실제로 막는 주체는 확인하지 못함(확인 불가)
- 실습 VM(2026-11-04)에서 AppLocker 스크립트 기본 규칙으로 같은 증상을 재현함: 사용자 폴더 모듈 차단, Program Files 모듈 통과. 이벤트 로그 ID 8007(차단)·8005(허용)로 확인했고, 허용 규칙을 병합하자 두 위치 모두 통과함
- 이 재현은 AppLocker로도 같은 증상이 난다는 것까지이며, 회사 PC가 AppLocker였다는 뜻은 아님(WDAC·SRP 등은 시험하지 않음)

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 이 PC와 테넌트에서 직접 실행해 읽었고, PC 이름도 적지 않았습니다. 재현 절의 값은 실습 VM에서 직접 실행해 읽은 값입니다.

---

## 전체 기록

### 1. 증상

- 모듈 설치 중 `authenticode signature … is not valid`(서명이 올바르지 않음) 오류
- 사용자 폴더(`Documents\WindowsPowerShell\Modules`)의 모듈이 정책에 막힘, 서식 파일(`.ps1xml`)만 막히기도 함

### 2. 원인 및 분석

"없다"와 "있는데 막힌다"는 대처가 달라 위치 → 버전 → 오류 문구 순으로 봤습니다. 실행 정책이 모듈 본체(`.psm1`)와 서식 파일(`.ps1xml`)도 막을 수 있다는 점은 문서에 있습니다([about_Execution_Policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)).

같은 날 막힌 PC는 사용자 폴더 / 통과한 PC는 Program Files 모듈이었습니다(조회, 서로 다른 PC).

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

- 어디에 설치됐나: `Get-Module -ListAvailable <모듈>`의 경로
    - 사용자 폴더 모듈은 막힌 PC에서 막혔고, Program Files 모듈은 통과한 PC에서 불러와졌음(조회, 각 1대)
- 어느 버전의 PowerShell인가: `$PSVersionTable.PSVersion`
    - 7과 5.1은 모듈 위치와 호환 규칙이 다름
- 막힘 메시지가 무엇인가: Import-Module 오류 문구
    - "인식되지 않음"=모듈 없음, "정책/서명"=막힘

**점검 스크립트로 모듈별 불러오기 시험.** 사용자 폴더 모듈을 빼고 Program Files의 원본만 두고, PowerShell 7과 5.1에서 각각 `Import-Module`을 시험했습니다(조회).

**막힌 PC.** 사용자 폴더와 키트 폴더에 복사한 모듈도 막혔습니다. 모듈 본체(`.psm1`), 서식 파일(`.ps1xml`), 모듈 시작 스크립트가 모두 막혔고 폴더를 바꿔도 같았습니다. 사용자가 확인해 보니 PC에 적용된 그룹 정책은 없다고 했습니다. 이 PC에서 모듈을 Program Files에 설치해 시험하지는 않았습니다.

**통과한 PC.** 전체 사용자 위치에 설치된 모듈로 시험한 결과는 이렇습니다(조회).

```text
Microsoft.Graph.Authentication   PS7: 성공 · PS5.1: 성공
Az.Accounts                      PS7: 성공 · PS5.1: 성공
MicrosoftTeams                   PS7: 성공 · PS5.1: 성공
ExchangeOnlineManagement         PS7: 성공 · PS5.1: 성공
SharePoint 모듈 16.0.27612.12000 (5.1) : 불러오기 성공
```

**막힌 PC에서의 대체 경로.** SharePoint 모듈은 Windows PowerShell 5.1에서는 사용자 폴더에 있어도 불러와졌습니다(조회). 나머지 모듈을 5.1에서 실행하는 것은 시도하지 않았습니다.

</details>

### 3. 실습 VM 재현 (2026-11-04)

회사 PC의 증상(사용자 폴더 모듈 차단, Program Files 모듈 통과)이 정책 한 가지로 재현되는지 Hyper-V 실습 VM에서 시험했습니다. 시험 전 체크포인트를 만들어 두었고, 시험은 Windows 10 Enterprise VM에서 도메인 사용자 `cloudtest01`의 비상승(UAC 상승하지 않은) 토큰으로 했습니다. 시험용 모듈 `LabMod.psm1`을 사용자 폴더(`Documents\WindowsPowerShell\Modules`)와 Program Files(`Program Files\WindowsPowerShell\Modules`) 두 곳에 같은 내용으로 두고, 설정을 한 단계씩 바꿔 가며 새 PowerShell 프로세스에서 `Import-Module`을 시험했습니다(조회, VM 1대).

| 단계 | 사용자 폴더 모듈 | Program Files 모듈 |
|---|---|---|
| 1. 실행 정책 Restricted(기본) | 차단 | 차단 |
| 2. 실행 정책 RemoteSigned만(AppLocker 없음) | OK | OK |
| 3. RemoteSigned + AppLocker 스크립트 기본 규칙 3개 | 차단 | OK |
| 4. 3단계에 사용자 폴더 허용 규칙 병합 | OK | OK |

- 1단계: 두 위치 모두 불러오지 못했습니다. Restricted에서는 스크립트 파일 실행이 안 된다는 문서 설명([about_Execution_Policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies))과 같은 결과입니다. 이 단계의 오류 문구는 따로 기록하지 않았습니다.
- 3단계에서 적용한 AppLocker 스크립트 기본 규칙은 3개입니다. Windows 폴더 안 스크립트 허용, Program Files 안 스크립트 허용, 관리자에게 모든 스크립트 허용입니다. 규칙은 `Set-AppLockerPolicy`로 적용했고 Application Identity 서비스(AppIDSvc)는 실행 중이었습니다.
- 사용자 폴더 모듈의 차단 메시지 전문은 다음과 같습니다(그림 2).

```text
그룹 정책을 사용하여 만든 정책 같은 소프트웨어 제한 정책에 의해 작업이 차단되었으므로 C:\Users\cloudtest01\Documents\WindowsPowerShell\Modules\LabMod\LabMod.psm1 파일을 로드할 수 없습니다.
```

![VM에서 실행 정책 Restricted와, RemoteSigned에 AppLocker 스크립트 규칙을 더한 단계를 나란히 시험한 PowerShell 화면]({{ "/assets/images/2026/10/m23-4-vm-policy-compare-1104.png" | relative_url }})
*그림 1. 17:51:49 시험 화면의 위쪽 일부(사용자 sionnote\cloudtest01). ExecutionPolicy=Restricted(기본)에서는 사용자 폴더와 Program Files의 LabMod.psm1이 모두 [BLOCKED]입니다. ExecutionPolicy=RemoteSigned + AppLocker script rules(3)에서는 사용자 폴더가 [BLOCKED], Program Files가 [OK]입니다. 이 그림에는 위 두 단계만 보입니다.*

![VM에서 사용자 폴더 모듈과 스크립트는 소프트웨어 제한 정책에 의해 차단되고 Program Files 모듈은 불러와진 PowerShell 화면]({{ "/assets/images/2026/10/m23-3-vm-applocker-block-1104.png" | relative_url }})
*그림 2. 17:52:22 시험 화면(ExecutionPolicy=RemoteSigned, LanguageMode=FullLanguage). 사용자 폴더의 LabMod.psm1은 [BLOCKED]이고 "그룹 정책을 사용하여 만든 정책 같은 소프트웨어 제한 정책에 의해 작업이 차단되었으므로 … 파일을 로드할 수 없습니다"가 출력됩니다. Program Files의 LabMod.psm1은 [OK]이고 LabMod가 Program Files 경로에서 로드되었다고 나옵니다. 사용자 폴더의 lab-test.ps1도 같은 문구로 [BLOCKED]입니다.*

**관찰한 점 세 가지.**

- 적용 시점: 규칙을 적용한 직후(17:49~17:50)에 새 프로세스로 시험했을 때는 두 위치 모두 OK였고, 17:51:49 이후 시험부터 사용자 폴더 모듈이 차단되었습니다. 정책 반영에 수 분 걸린 것으로 보이지만 원인은 확인하지 못했습니다. 정책을 적용한 직후 한 번 시험해서 "막히지 않는다"고 결론 내리면 안 된다는 뜻입니다.
- 지원 형식: `Test-AppLockerPolicy`는 `.psm1`을 `UnsupportedFileTypeException`으로 답했습니다. AppLocker 지원 형식은 Exe, Dll, Windows Installer, 스크립트로 표시되었습니다. 그런데도 PowerShell은 `.psm1` 모듈 파일을 차단했습니다. 따라서 `Test-AppLockerPolicy` 결과만으로 모듈이 안전하다고 판단할 수 없었습니다.
- 메시지 문구: 이 VM에서는 로컬 정책(`Set-AppLockerPolicy`)으로 규칙을 넣었는데도 차단 메시지에 "그룹 정책을 사용하여 만든 정책"이라는 문구가 나왔습니다. 그래서 이 문구만으로는 그룹 정책이 적용되었는지 알 수 없었습니다.

### 4. 원인 확인 명령

차단 직후에 AppLocker 이벤트 로그 `Microsoft-Windows-AppLocker/MSI and Script`를 읽으면 무엇이 막혔는지 경로 단위로 나옵니다. 이벤트 ID 8007은 "실행할 수 없습니다"(차단), 8005는 "실행할 수 있습니다"(허용)입니다. 유효 정책(Effective)은 `Get-AppLockerPolicy -Effective`로 읽습니다. 그림 3의 출력은 VM에서 읽은 실제 값이고, 이미지에는 명령 줄이 찍히지 않아 아래 명령은 같은 내용을 읽는 표준 형태로 적었습니다.

```powershell
# 차단(8007)·허용(8005) 이벤트 읽기
Get-WinEvent -LogName 'Microsoft-Windows-AppLocker/MSI and Script' -MaxEvents 20 |
    Where-Object { $_.Id -in 8005, 8007 } |
    Format-Table TimeCreated, Id, Message -AutoSize -Wrap

# 유효(Effective) 정책 중 스크립트 규칙 확인
(Get-AppLockerPolicy -Effective).RuleCollections |
    Where-Object { $_.RuleCollectionType -eq 'Script' }
```

![VM의 AppLocker 이벤트 로그에서 8007과 8005 이벤트, 유효 정책의 스크립트 규칙 경로가 출력된 PowerShell 화면]({{ "/assets/images/2026/10/m23-5-vm-applocker-eventlog-1104.png" | relative_url }})
*그림 3. 17:53:09 화면. 17:52:22에 ID=8007로 %OSDRIVE%\USERS\CLOUDTEST01\DOCUMENTS\LAB-TEST.PS1과 …\WINDOWSPOWERSHELL\MODULES\LABMOD\LABMOD.PSM1이 "실행할 수 없습니다", ID=8005로 %PROGRAMFILES%\WINDOWSPOWERSHELL\MODULES\LABMOD\LABMOD.PSM1이 "실행할 수 있습니다"로 기록되었습니다. 아래 유효 정책의 스크립트 규칙은 LAB (Default) scripts in Windows folder, scripts in Program Files, all scripts for Administrators 세 개이고 경로는 `%WINDIR%\*`, `%PROGRAMFILES%\*`, `*`입니다.*

이 이벤트 로그가 있다는 것은 AppLocker가 그 파일을 판정했다는 뜻입니다. 회사 PC에서 같은 로그를 읽어 본 것은 아닙니다(접근 범위 밖). 로그에 8007이 없다고 해서 AppLocker가 아니라고 단정하지도 못합니다.

### 5. 사용 가능하게 만드는 방법

**① 정책을 바꾸지 않는 우회: Program Files 모듈 경로에 설치합니다.** 관리자 권한 PowerShell에서 전체 사용자 위치에 설치하거나, 해당 경로로 직접 받습니다.

```powershell
Install-Module <이름> -Scope AllUsers
# 또는
Save-Module -Name <이름> -Path 'C:\Program Files\WindowsPowerShell\Modules'
```

VM에서는 시험용 `LabMod`를 Program Files 위치에 두었을 때 AppLocker 기본 규칙 아래에서도 불러와진 것까지만 확인했습니다. `Install-Module` 자체는 실습 VM의 아웃바운드가 막혀 있어 실행하지 않았습니다.

**② 정책 소유자(관리자)가 허용 규칙을 병합합니다.** 아래는 VM에서 실행한 순서와 같은 흐름입니다. 규칙 XML을 만든 뒤 `-Merge`로 기존 정책에 더했습니다. 허용 경로는 `%OSDRIVE%\Users\*\Documents\WindowsPowerShell\Modules\*`입니다. 아래 XML은 그 규칙(스크립트 컬렉션, 모든 사용자 허용, 위 경로)을 표현한 최소 형태의 예시이며 VM에서 쓴 파일 원본은 아닙니다. 규칙 Id는 새 GUID로 바꿔 쓰십시오.

```xml
<AppLockerPolicy Version="1">
  <RuleCollection Type="Script" EnforcementMode="Enabled">
    <FilePathRule Id="11111111-2222-3333-4444-555555555555" Name="LAB allow user module folder" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePathCondition Path="%OSDRIVE%\Users\*\Documents\WindowsPowerShell\Modules\*" />
      </Conditions>
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
```

```powershell
Set-AppLockerPolicy -XmlPolicy 'C:\Temp\allow-usermodules.xml' -Merge
```

17:54:18에 병합했고 20초 뒤인 17:54:38에 비관리자 새 프로세스로 시험하자 사용자 폴더 모듈과 Program Files 모듈 모두 [OK]였습니다(그림 4). 3단계 적용 때는 반영에 수 분이 걸린 것으로 보였던 것과 달리 이번에는 20초 만에 바뀐 것으로 관찰되었습니다.

![VM에서 허용 규칙 병합 후 사용자 폴더와 Program Files의 LabMod.psm1이 모두 OK로 나온 PowerShell 화면]({{ "/assets/images/2026/10/m23-6-vm-allow-rule-fixed-1104.png" | relative_url }})
*그림 4. 17:54:38 화면(제목 줄에 "allow rule merged at 17:54" 표시). 사용자 폴더의 LabMod.psm1과 Program Files의 LabMod.psm1이 모두 [OK]입니다.*

(의견) 사용자가 쓸 수 있는 경로를 통째로 허용하면 AppLocker 통제가 약해집니다. 그 경로에는 일반 사용자가 파일을 넣을 수 있기 때문입니다. 그래서 허용이 필요하면 경로 규칙보다 게시자(서명) 규칙이나 해시 규칙을 쓰거나, ①처럼 Program Files에 설치하는 쪽을 권합니다. 위 경로 규칙은 VM에서 원리를 확인하기 위한 것입니다.

**③ 실행 정책이 원인일 때:** 현재 창에서만 RemoteSigned로 바꿉니다.

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
```

VM의 시험에서 프로세스 범위로 바꾼 RemoteSigned는 AppLocker 규칙이 없을 때 두 위치 모두 통과시켰습니다. 반대로 AppLocker 규칙이 있을 때는 RemoteSigned여도 사용자 폴더 모듈이 차단되었습니다(그림 2). 따라서 ③은 실행 정책 때문에 막힌 경우에만 해당합니다.

### 6. 결론

`사용자 폴더 모듈 → 정책에 막힘 → Import-Module 실패`

회사의 두 PC는 서로 다른 PC여서 위치가 원인인지는 가리지 못했습니다. 실습 VM에서는 같은 VM, 같은 사용자로 위치만 바꿔 비교했고, AppLocker 스크립트 규칙 아래에서는 사용자 폴더 모듈만 차단되고 Program Files 모듈은 통과했습니다(3절).

이것은 실습 VM에서 AppLocker 규칙으로 같은 증상을 재현한 것입니다. 회사 PC를 실제로 막은 주체가 AppLocker였는지는 이 시험으로 확인되지 않았습니다. 확인하지 못한 것:

- 회사 PC의 막는 주체: 확인 불가. 그룹 정책은 없다고 사용자가 확인했습니다. 회사 PC의 AppLocker 이벤트 로그와 유효 정책 조회는 접근 범위 밖이라 하지 못했습니다. 실습 VM에서는 WDAC와 소프트웨어 제한 정책(SRP)을 시험하지 않았고, Smart App Control·보안 프로그램도 확인하지 않았습니다.
- 막힌 PC의 5.1 대체 실행: SharePoint 모듈만 5.1에서 불러와짐(조회). 나머지 모듈은 시도하지 않음.

### 7. 권고방안

1. 시도해 볼 조치(막힌 PC에서는 시험 전): 모듈을 Program Files(전체 사용자 위치)에 설치하고 7과 5.1 중 되는 쪽으로 실행합니다. 설치는 관리자 창에서 한 번, 실행은 일반 창에서 합니다.
2. 조치 후 확인: `Import-Module`이 "정책/서명" 오류 없이 끝나면 됩니다. 둘 다 막히면 Cloud Shell을 쓰되 안 되는 모듈이 있어 범위를 먼저 봅니다.
3. 하지 말아야 할 것: 회사 PC에서 정책을 스스로 풀거나 우회하지 않습니다(회사 PC 보안 설정은 작업 범위 밖). 5절의 ②는 정책 소유자(관리자)가 할 일이고, 위 시험은 실습 VM에서만 했습니다. 주체를 모르면 "막힘, 주체 확인 불가"로 적고 시도한 방법과 못 한 사유(이벤트 로그·유효 정책 조회 여부 포함)를 함께 적습니다.

관련 글: [문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }}) · [같은 세션에서 두 서비스 모듈을 불러오면 DLL이 충돌함]({{ "/m365/troubleshooting/module-dll-conflict-same-session/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- 문서: PowerShell 7과 Windows PowerShell 5.1의 모듈 호환, [about_PowerShell_Editions](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_powershell_editions)
- 문서: 실행 정책(Execution policy)과 Group Policy 설정 설명. SRP·AppLocker·WDAC에 대한 설명은 아님, [about_Execution_Policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- 조회: 두 PC의 모듈 불러오기 시험 결과 (출처: 10/28 점검 로그)
- 조회: 실습 VM의 단계별 불러오기 시험, AppLocker 이벤트 로그 8007·8005, 유효 정책, 허용 규칙 병합 후 시험 (2026-11-04 17:46~17:55, 그림 1~4)
- 확인 불가: 회사 PC의 막는 주체(SRP·로컬 보안 정책 / Smart App Control / WDAC / AppLocker / 보안 프로그램)
    - 시도(사용자 확인): 적용된 그룹 정책 유무 확인(없음).
    - 시도(실습 VM): AppLocker 스크립트 규칙으로 같은 증상 재현. 재현은 가능했으나 회사 PC가 AppLocker였다는 근거는 아님.
    - 시도하지 않은 것: 회사 PC의 AppLocker 이벤트 로그·유효 정책 조회, SRP·Smart App Control·WDAC·보안 프로그램 점검(WDAC·SRP는 VM에서도 시험하지 않음).
    - 사유: 회사 PC 보안 설정은 작업 범위 밖.

</details>
