---
title: "[Troubleshooting] 빈 값(null) 때문에 스크립트 계산이 실패하거나 항목이 누락되고, 결과 표의 이름 열이 섞임"
date: 2026-10-26 15:00:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 5
tags: [Troubleshooting, PowerShell, "null", 날짜 계산, 결과 표, 앱 등록]
excerpt: "빈 칸(null)을 계산하다 예외·누락이 나고 이름 열이 섞였다. null 검사와 열 분리로 예외 없이 돌게 고쳤다"
toc: true
---

화면에서 "빈 칸"이던 값을 스크립트로 계산하자 예외가 나거나 집계에서 빠졌고, 결과 표의 이름 열은 서로 섞였습니다. null을 "0"처럼 다룬 가정과 두 곳에 쓴 같은 `DisplayName`이 원인이어서, null 검사와 열 분리(`App`·`CredentialName`)로 예외 없이 돌게 고쳤습니다.

## 요약

- 예외와 누락은 null을 값이 있는 것처럼 다룬 스크립트 가정 탓임
- 계산 전에 null을 검사하고 한 열이 한 가지 개체만 가리키게 하면 됨
- 결과 표에는 해당 없음과 정상, 확인 불가를 서로 다른 값으로 적어야 함

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- 사례 1: 화면에서 빈 칸이던 날짜로 경과 시간을 계산하자 `Cannot convert null to type "System.DateTime"` 예외(조회)
- 사례 2: 앱 등록 자격증명 만료 표에서 앱 이름과 자격증명 이름이 둘 다 `DisplayName`이라 구분 안 됨(조회)

### 2. 원인 및 분석

화면의 빈 칸은 스크립트에서 null인데, 값이 있는 것처럼 다뤘습니다.

| 대상 | 문제 | 고친 것 |
|---|---|---|
| 온프레미스 동기화를 한 적 없는 테넌트의 "마지막 동기화 시각" | 현재 시각에서 빼는 계산이 예외 | "동기화 미구성(해당 없음)"으로 출력 |
| 정책의 "수정 시각" | 비교가 거짓이 되어 누락 | 생성 시각을 대신 사용 |
| 로그인 기록이 없는 사용자 | "오래 로그인하지 않음"과 섞여 집계 | 기록 없음을 따로 셈 |

사례 2는 한 열이 두 개체를 가리킨 탓입니다. 서비스 주체 자격증명도 만료 대상이라 따로 집계했습니다(조회).

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

실패한 항목의 대상 값이 null인지부터 봤고, 결과 표는 한 열이 한 가지 개체만 가리키는지 봤습니다.

![null 값 계산 예외가 포함된 실패 사유 목록]({{ "/assets/images/2026/10/script-failure-types.png" | relative_url }})
*그림 1. 날짜 값이 null이거나 배열일 때 나온 예외(`Cannot convert null to type "System.DateTime"`, `Cannot convert the "System.Object[]" value ... to type "System.DateTime"`). 두 줄 외에는 다른 유형의 실패입니다. 항목 번호와 일부 안내 문구는 가렸습니다.*

![온프레미스 동기화 실행 이력이 없는 Microsoft Entra Connect 동기화 화면]({{ "/assets/images/2026/10/sync-never-run.png" | relative_url }})
*그림 2. Microsoft Entra Connect > 동기화 연결. "마지막 동기화"가 "동기화 실행된 적 없음"이라 시각 값 자체가 비어 있습니다. 이 값에서 현재 시각을 빼는 계산이 위 예외의 원인이었습니다.*

수정 시각 누락, 로그인 기록 없는 사용자 집계, 이름 열 혼동은 화면 값이 아니라 스크립트의 계산과 표 형태 문제이고, 당시 출력 화면이 남아 있지 않아 캡처를 넣지 못했습니다.

```powershell
# null 검사 예: 마지막 동기화 시각이 없으면 경과 시간을 계산하지 않는다
$last = $org.OnPremisesLastSyncDateTime
if ($null -eq $last) { '동기화 미구성(해당 없음)' }
else { [int]((Get-Date) - $last).TotalMinutes }
```

</details>

### 3. 결론

`null을 값처럼 계산 → 예외·누락·혼합 집계`, `한 열에 두 개체 → 이름 구분 불가`

null 검사와 열 분리(`App`·`CredentialName`)로 예외 없이 돌게 고쳤습니다. 테넌트 설정은 바꾸지 않아 원복할 것이 없습니다.

### 4. 권고방안

1. 조치: 계산 전에 null을 검사하고(예시 코드는 확인 과정에), null은 "0"도 "오래됨"도 아닌 "없음" 상태로 출력합니다.
2. 조치 후 확인: 결과 표에 해당 없음 / 정상 / 확인 불가가 서로 다른 값으로 나오고, null 비교로 빠진 항목이 없으면 됩니다.
3. 표를 만들기 전 한 열이 한 가지 개체만 가리키는지 봅니다.

관련 글: [조회 스크립트 결과가 전부 실패로 나올 때]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }}) · [화면 값과 명령 값이 다를 때]({{ "/m365/troubleshooting/screen-vs-command-value-mismatch/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- **조회**: null 계산 예외, 수정 시각 누락, 로그인 기록 없음 혼합 집계
    - 출처: 10/24~10/26 조회 스크립트 실행
- **조회**: 결과 표 이름 열 혼동과 열 분리
    - 출처: 앱 등록 자격증명 만료 표

</details>
