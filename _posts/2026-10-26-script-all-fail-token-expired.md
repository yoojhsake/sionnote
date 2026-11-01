---
title: "[Troubleshooting] 조회 스크립트 결과가 전부 실패로 나옴: 토큰 만료와 오류 유형 구분"
date: 2026-10-26 14:20:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 3
tags: [Troubleshooting, PowerShell, Graph, 토큰 만료, Unauthorized, Forbidden, Connect-MgGraph]
excerpt: "조회 스크립트가 전 항목 실패했다. 토큰 만료부터 의심해 재연결하니 정상, 남은 실패는 유형별로 나눠 처리했다"
toc: true
---

여러 항목을 한 번에 읽는 스크립트가 전부 "측정 불가"로 끝나고, 오류는 Unauthorized 계열 문구뿐이었습니다. 항목마다 따로 보기 전에 공통 원인인 토큰 만료부터 의심해 다시 연결하자, 같은 스크립트가 전 항목 정상으로 돌았습니다.

## 요약

- 전 항목이 같은 모양으로 실패한 원인은 토큰 만료였고 재연결로 해결됨
- 전부 같으면 연결부터 보고, 남은 실패는 오류 유형별로 나눠 처리하면 됨
- 토큰의 정확한 만료 시각은 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- 여러 항목을 읽는 스크립트가 전부 같은 모양의 "측정 불가"로 끝나고, 오류는 "Unauthorized" 계열(조회)

![모든 줄이 같은 "측정 불가"로 끝난 스크립트 실행 결과]({{ "/assets/images/2026/10/script-all-unmeasurable.png" | relative_url }})
*그림 1. 재연결 전 실행 결과의 앞부분. 모든 줄이 같은 모양("측정 불가")으로 끝났습니다. 줄 앞의 항목 번호는 가렸습니다.*

### 2. 원인 및 분석

| 결과 | 가능성이 큰 원인 |
|---|---|
| 항목별로 제각각 실패 | 항목마다 다른 권한·환경 문제 |
| **전부 동시에 같은 모양으로 실패** | **공통 원인**(로그인·토큰) |

이번은 공통 원인 쪽이었고, 재연결 후 정상 동작해(조회) 토큰 만료로 판단했습니다. 재연결 뒤 남은 실패는 세 유형입니다.

| 메시지 | 뜻 | 처리 |
|---|---|---|
| `Response status code does not indicate success: Forbidden (Forbidden)` | 토큰의 Graph 범위·Entra 역할 부족(사람 권한 아님) | 범위·역할 확인 후 동의, 안 되면 화면 경로로 대체 |
| `Session is not established`(Teams 미접속 등) | 서비스 미연결 | 서비스별 연결 먼저(예: `Connect-MicrosoftTeams`) |
| `Cannot convert null to type "System.DateTime"` 등 | 값 형태 가정이 어긋남 | 값 없음·배열 처리 추가 |

<details markdown="1">
<summary>재연결 뒤 남은 실패 사유 보기 (그림 1장)</summary>

![한 번 실행에서 남은 실패 사유 목록]({{ "/assets/images/2026/10/script-failure-types.png" | relative_url }})
*그림 2. 한 번 실행에서 남은 실패 사유 목록. Forbidden, Teams 세션 미접속, DateTime 값 변환 오류가 섞여 있습니다. 항목 번호와 일부 안내 문구는 가렸습니다.*

</details>

### 3. 결론

`토큰 만료 → 전 항목 Unauthorized → 결과 전부 "측정 불가"`

재연결 후 재실행으로 해결했습니다(읽기 전용, 되돌릴 변경 없음). 토큰의 정확한 만료 시각은 확인 불가입니다(시도: 재연결 후 재실행으로 원인만 확인 / 막힌 이유: 만료 시각을 따로 읽지 않음).

### 4. 권고방안

1. 조치: 전부 같은 모양으로 실패하면 연결과 토큰부터 보고 다시 연결합니다(스크립트 안내문에도 "전 항목이 Unauthorized로 나오면 토큰 만료이니 재연결 후 재실행"을 적음).

    ```powershell
    # 다시 연결(필요한 범위를 명시). Cloud Shell 등에서 대화형 동의가 어려우면 환경에 맞는 로그인 방법을 쓴다.
    Connect-MgGraph -Scopes "Directory.Read.All","Policy.Read.All"
    ```

    > 위 범위는 예시입니다. 실제로 읽는 항목에 필요한 범위를 확인해 맞춥니다.

2. 조치 후 확인: Unauthorized가 사라지면 됩니다. 남은 실패는 위 표대로 처리하고, 연결 직후 토큰 정보를 기록해 만료 시점과 대조합니다.
3. 하지 말아야 할 것: 읽지 못한 항목을 비워 두지 않습니다("확인 불가 + 시도 + 사유 + 다음 방법").

관련 글: [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) · [명령이 모듈 없음, 환경에 따라 접속 안 됨]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }}) · [빈 값(null)에서 계산 오류와 누락]({{ "/m365/troubleshooting/null-values-in-scripts/" | relative_url }}) · [$top=999인데 100건만 올 때]({{ "/m365/troubleshooting/graph-paging-100-limit/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- **조회**: 전 항목 동일 실패 후 재연결로 정상 동작, 유형별 실패 메시지 (출처: 10/24~10/26 조회 스크립트 실행)
- **확인 불가**: 토큰의 정확한 만료 시각
    - 시도: 재연결 후 재실행으로 원인만 확인.
    - 막힌 이유: 만료 시각을 따로 읽지 않음.
    - 다음 방법: 연결 직후 토큰 정보를 기록해 두고 만료 시점과 대조

</details>
