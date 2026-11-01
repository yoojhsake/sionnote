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

- 여러 항목을 한 번에 읽는 스크립트 결과가 전부 "측정 불가"(실패), 오류는 Unauthorized 계열 문구뿐
- 실패가 항목마다 제각각인지, 전부 같은 모양인지부터 나눔. 전부 같아서 토큰 만료로 판단
- 다시 연결하고 재실행하자 전 항목 정상(조회). 만료 시각은 확인하지 않음(근거 자료의 확인 불가 항목)
- 남은 실패는 Forbidden, 세션 미접속, 값 변환 오류로 묶어 따로 처리. 유형마다 처리가 다름(아래 "재연결 뒤에도 남은 실패")

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

한 번에 여러 항목을 읽는 스크립트를 돌렸더니 결과가 전부 "측정 불가"(실패)로 나왔습니다. 항목마다 원인이 다른 게 아니라 **전부 같은 모양**이었고(조회), 오류 문구는 "Unauthorized" 계열이었습니다.

![모든 줄이 같은 "측정 불가"로 끝난 스크립트 실행 결과]({{ "/assets/images/2026/10/script-all-unmeasurable.png" | relative_url }})
*그림 1. 재연결 전 실행 결과의 앞부분. 모든 줄이 같은 모양("측정 불가")으로 끝났습니다. 줄 앞의 항목 번호는 가렸습니다.*

### 2. 원인과 해결

#### 전부 실패한 이유: 토큰 만료

다시 연결한 뒤 같은 스크립트가 정상 동작해서(조회) 토큰 만료로 판단했습니다. 토큰이 정확히 언제 만료됐는지는 확인하지 않았습니다.

```powershell
# 다시 연결(필요한 범위를 명시). Cloud Shell 등에서 대화형 동의가 어려우면 환경에 맞는 로그인 방법을 쓴다.
Connect-MgGraph -Scopes "Directory.Read.All","Policy.Read.All"
```

> 위 범위는 예시입니다. 실제로 읽는 항목에 필요한 범위를 확인해 맞춥니다.

#### 재연결 뒤에도 남은 실패

한 번 실행에서 남은 실패 메시지는 크게 세 가지였고, 유형마다 처리가 다릅니다.

- **`Response status code does not indicate success: Forbidden (Forbidden)`**
    - 뜻: 토큰의 Graph 범위나 Entra 역할이 부족(사람의 권한이 아님)
    - 처리: 필요한 범위와 역할을 확인하고 동의, 안 되면 같은 값을 읽는 화면 경로로 대체
- **`Session is not established`(Teams 미접속 등)**
    - 뜻: 해당 서비스에 연결하지 않고 명령을 실행
    - 처리: 서비스별 연결 명령을 먼저 실행(예: Teams는 `Connect-MicrosoftTeams`)
- **`Cannot convert null to type "System.DateTime"` 등**
    - 뜻: 스크립트가 값 형태를 가정했는데 어긋남
    - 처리: 값이 없거나 배열일 때의 처리를 추가

#### 대처와 원복

다시 연결하고 재실행했습니다. 스크립트 안내문에도 "전 항목이 Unauthorized로 나오면 토큰 만료이니 재연결 후 재실행"을 적어 두었습니다. 읽기 전용 조회였으니 되돌릴 설정 변경은 없습니다.

유형별로 이어지는 글은 다음과 같습니다.
    - Forbidden: [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})
    - 세션 미접속: [명령이 모듈 없음, 환경에 따라 접속 안 됨]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }})
    - 값 변환 오류: [빈 값(null)에서 계산 오류와 누락]({{ "/m365/troubleshooting/null-values-in-scripts/" | relative_url }})

### 3. 스크립트를 돌릴 때 습관

실행 전에 연결 상태(토큰 만료 여부), 서비스별 연결, 필요한 범위와 역할을 확인합니다. 결과가 전부 같은 모양으로 실패했다면 공통 원인인 연결과 토큰부터 봅니다. 남은 실패 메시지는 Forbidden, 연결 없음, 값 변환 오류로 묶어서 처리합니다.

읽지 못한 항목은 비워 두지 않고 "확인 불가 + 시도한 방법 + 사유 + 다음 방법"으로 남깁니다.

### 4. 확인 과정(시도와 결과)

실패의 모양부터 봤습니다.

| 결과 | 가능성이 큰 원인 |
|---|---|
| 항목별로 제각각 실패 | 항목마다 다른 권한·환경 문제 |
| **전부 동시에 같은 모양으로 실패** | **공통 원인**(로그인·토큰) |

이번에는 공통 원인 쪽이었습니다. 개별 항목의 원인을 하나씩 찾기 전에 연결 상태부터 봤다면 시간을 더 아꼈을 것입니다.

재연결 뒤 한 번 실행에서 남은 실패 사유는 아래 그림과 같습니다. 위 "재연결 뒤에도 남은 실패"의 세 유형이 섞여 있습니다.

![한 번 실행에서 남은 실패 사유 목록]({{ "/assets/images/2026/10/script-failure-types.png" | relative_url }})
*그림 2. 한 번 실행에서 남은 실패 사유 목록. Forbidden, Teams 세션 미접속, DateTime 값 변환 오류가 섞여 있습니다. 항목 번호와 일부 안내 문구는 가렸습니다.*

### 5. 관련 글

[Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}), [$top=999인데 100건만 올 때]({{ "/m365/troubleshooting/graph-paging-100-limit/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- **조회**: 전 항목 동일 실패 후 재연결로 정상 동작, 유형별 실패 메시지 (출처: 10/24~10/26 조회 스크립트 실행)
- **확인 불가**: 토큰의 정확한 만료 시각
    - 시도: 재연결 후 재실행으로 원인만 확인.
    - 막힌 이유: 만료 시각을 따로 읽지 않음.
    - 다음 방법: 연결 직후 토큰 정보를 기록해 두고 만료 시점과 대조

</details>
