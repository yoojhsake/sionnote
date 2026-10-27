---
title: "[Troubleshooting] 문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음"
date: 2026-10-26 15:40:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 7
tags: [Troubleshooting, PowerShell, Microsoft Graph 모듈, Cloud Shell, AudienceNotSupported, Windows PowerShell 5.1]
excerpt: "Graph 하위 모듈 누락, Cloud Shell 토큰으로 접속되지 않는 서비스 모듈, 서비스별 연결을 모듈 · 연결 · 권한 순서로 나눠 푼 기록"
toc: true
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell·Graph에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유·다음 방법 병기). 계정·테넌트 식별자는 게시하지 않았다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | 문서에 있는 예제 명령이 그대로는 실행되지 않음 |
| 먼저 나눈 것 | (1) 모듈, (2) 연결, (3) 권한 순서 |
| 원인 | 별도 하위 모듈 필요, Cloud Shell의 Azure 토큰으로는 서비스 PowerShell 접속 불가, 서비스별 연결 누락 |
| 대처 | 모듈을 명시하거나 REST로 조회, 내 PC의 Windows PowerShell 5.1에서 직접 로그인, 서비스별 연결 명령 실행 |
| 결과 | **조회**: 세 가지 모두 위 방법으로 값을 읽음 |

---

## 전체 기록

### 1. 증상

문서에 있는 예제 명령이 그대로는 실행되지 않았습니다. 상황은 세 가지였습니다.

- `Get-MgServiceAnnouncementMessage` 같은 Graph 명령이 인식되지 않았습니다.
- SharePoint·Teams 관리 명령이 Cloud Shell에서 접속되지 않았습니다.
- Teams·Exchange 명령이 연결 없이 실행되어 실패했습니다.

### 2. 먼저 확인할 것

명령이 안 될 때는 **(1) 모듈, (2) 연결, (3) 권한** 순서로 나눠 봅니다. 오류 메시지가 다르기 때문에 문구만으로도 구분됩니다.

| 오류 문구 | 가리키는 곳 |
|---|---|
| "인식되지 않는다" | 모듈이 없음 |
| "세션이 없다"(`Session is not established`) | 연결이 없음 |
| Forbidden | 권한(토큰 범위·역할) 문제 |

### 3. 시도와 결과

| 상황 | 원인 | 처리 |
|---|---|---|
| `Get-MgServiceAnnouncementMessage` 같은 Graph 명령이 인식되지 않음 | 해당 명령은 **별도 하위 모듈**(`Microsoft.Graph.Devices.ServiceAnnouncement`)에 있음. `Connect-MgGraph`만으로는 불러지지 않음(문서) | 모듈을 명시해 설치·가져오기, 또는 **REST로 직접 조회**(100건 페이징 글의 방식, 아래 관련 글 참고) |
| SharePoint·Teams 관리 명령이 Cloud Shell의 Azure 토큰으로는 접속되지 않음 | 그 토큰으로는 해당 서비스 PowerShell에 접속할 수 없었음(`AudienceNotSupported`, 조회) | 내 PC의 **Windows PowerShell 5.1**에서 각 모듈로 직접 로그인해 읽음(10/26, 조회). PowerShell 7에서는 호환 모드가 필요하다는 안내가 있음(문서, 직접 확인 아님) |
| Teams·Exchange 명령 | 각각 별도 연결이 필요 | `Connect-MicrosoftTeams`, `Connect-ExchangeOnline`을 서비스별로 먼저 실행 |

PowerShell 7에서의 호환 모드 동작은 직접 실행해 보지 않아 **확인 불가**입니다(시도: 문서 확인만 / 막힌 이유: 실행 환경으로 5.1을 사용 / 다음 방법: PowerShell 7에서 같은 명령을 실행해 결과 대조).

### 4. 대처와 원복

- 이 상황에서 테넌트 설정은 바꾸지 않았습니다. 모듈 설치는 실행 환경(내 PC)에만 영향을 줍니다.
- 문서의 예제를 쓸 때는 어느 모듈에 속한 명령인지와 어느 환경에서 실행하는지를 함께 기록했습니다.

### 5. 운영에서는 이렇게 판단한다

1. **모듈 → 연결 → 권한** 순서로 나눕니다. 이 순서를 지키면 같은 실패를 세 번 다른 방식으로 고치려 하지 않게 됩니다.
2. Graph 명령이 인식되지 않으면 하위 모듈을 확인하고, 모듈 없이 쓰려면 REST 호출로 대체합니다.
3. 서비스 PowerShell은 Cloud Shell 토큰으로 되지 않을 수 있으니, 되는 환경(내 PC의 Windows PowerShell 5.1)에서 직접 로그인합니다.
4. 서비스마다 연결 명령이 다르므로 스크립트 맨 앞에 서비스별 연결을 둡니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 메시지 센터 게시물 조회 명령·API | [List serviceAnnouncement messages](https://learn.microsoft.com/graph/api/serviceannouncement-list-messages?view=graph-rest-1.0) |
| 조회 | Cloud Shell 토큰으로 SharePoint·Teams 접속 시 `AudienceNotSupported` | Cloud Shell |
| 조회 | 내 PC Windows PowerShell 5.1에서 각 모듈 직접 로그인 후 읽기 | 10/26 |
| 확인 불가 | PowerShell 7 호환 모드 동작 | 시도: 문서 확인. 막힌 이유: 직접 실행하지 않음. 다음 방법: PowerShell 7에서 실행해 대조 |

관련 글: [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}), [Exchange 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}), [조회 스크립트 결과가 전부 실패로 나올 때]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }})
