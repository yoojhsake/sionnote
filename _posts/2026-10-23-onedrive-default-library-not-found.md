---
title: "[Troubleshooting] 관리자 OneDrive가 \"기본 문서 라이브러리를 찾을 수 없음\"으로 열리지 않을 때"
date: 2026-10-23 15:00:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 8
tags: [OneDrive, Graph, "403", 기본 문서 라이브러리, 회의 녹화, 채팅 파일]
excerpt: "오전엔 '기본 문서 라이브러리를 찾을 수 없음'과 403, 오후엔 정상으로 열렸습니다. 단정 대신 시간을 두고 다시 확인했습니다."
---

관리자 OneDrive를 열자 "기본 문서 라이브러리를 찾을 수 없음"이 뜨고 Graph `/me/drive`도 403이었습니다. 바로 단정하지 않고 시간을 두고 다시 열었더니 오후에는 정상으로 열렸습니다(오류가 사라진 이유는 확인 불가).

## 요약

- 관리자 OneDrive를 열면 "기본 문서 라이브러리를 찾을 수 없음" 오류. Graph `/me/drive`도 HTTP 403
- 오류가 사라진 이유는 **확인 불가**(프로비저닝 지연으로 추정). 403은 "대상이 없음"이 아니라 토큰에 Files 범위가 없는 쪽으로 보임
- 바로 단정하지 않고 시간을 두고 같은 화면을 다시 열어 확인
- 오후에 OneDrive 홈과 My files가 정상으로 열림. Meetings, Microsoft Copilot Chat Files, Recordings 폴더가 있고 모두 0개

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법과 사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

회의 녹화와 1:1 채팅 파일이 저장되는 위치를 확인하려고 관리자 OneDrive를 열었습니다. 오전에는 "기본 문서 라이브러리를 찾을 수 없음" 오류가 나서 열리지 않았습니다. 같은 시각에 Cloud Shell에서 Graph로 `/me/drive`를 읽었을 때도 HTTP 403이었습니다.

처음에는 이 403을 "OneDrive가 없어서"라고 추정했습니다.

### 2. 원인과 해결

시간을 두고 다시 열자 오후에는 정상으로 열렸습니다. 오류가 사라진 이유는 확인 불가이고, 프로비저닝 지연으로 추정할 뿐입니다.

OneDrive가 존재하니 `/me/drive`의 403을 "OneDrive가 없어서"로 본 처음 추정은 맞지 않았습니다. 정정하면, 이 403은 "대상이 없음"이 아니라 토큰에 Files 범위가 없는 쪽으로 읽는 것이 맞아 보입니다. 채널 전용 사이트의 파일 목록이 Graph 탐색기에서 Files.Read.All, Sites.Read.All을 동의하자 200으로 열렸던 것([비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}))이 같은 원인으로 보는 근거입니다.

대처는 오류 화면에서 바로 "없다"고 결론 내지 않고 시간을 두고 다시 여는 것이었습니다. 변경한 것은 없어 원복할 것도 없습니다(조회만 했습니다).

### 3. 이번 일로 정한 기준

403은 **"권한 없음"과 "대상이 없음"으로 나눠서** 봅니다. 대상이 없다는 결론은 화면에서 존재를 확인한 뒤에만 내립니다.

같은 화면은 시간을 두고 다시 열어 확인합니다. 오류가 사라진 이유를 모를 때는 모른다고 기록합니다.

### 4. 확인 과정

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 1장)</summary>

#### 살펴본 순서

1. 시간이 지난 뒤에도 같은가. 같은 화면을 시간을 두고 다시 엽니다.
2. 403을 "권한 없음"과 "대상이 없음"으로 나눕니다. 대상이 있다면 403은 권한이나 토큰 범위 쪽입니다.
3. 같은 토큰으로 되는 호출과 안 되는 호출을 비교합니다. 팀, 사용자, 채널 목록은 되고 파일과 드라이브 쪽만 막히는지 봅니다([Cloud Shell에서 Graph 호출: 되는 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})).

#### 오후에 다시 열어 본 결과

오후에 OneDrive 웹을 다시 열었더니 홈과 My files가 정상으로 열렸습니다(조회). GUI 경로는 Microsoft 365 앱 시작 관리자 → OneDrive → My files입니다. My files에는 **Meetings, Microsoft Copilot Chat Files, Recordings** 폴더가 있었고 모두 0개였습니다.

![OneDrive My files 화면. Meetings, Microsoft Copilot Chat Files, Recordings 폴더, 모두 0 items]({{ "/assets/images/2026/10/m03-4-onedrive.png" | relative_url }})
*그림 1. 관리자 OneDrive의 My files(GUI 경로: Microsoft 365 앱 시작 관리자 → OneDrive → My files). Meetings, Microsoft Copilot Chat Files, Recordings 폴더 3개가 모두 0 items입니다. 계정 이름 부분은 가렸습니다.*

문서가 설명하는 "개인 회의 녹화는 진행자의 OneDrive에 저장"되는 대상 폴더(Recordings)는 있는 상태입니다.

#### 확인 불가로 남은 것

- **동의 후 `/me/drive`가 200으로 열리는지**
    - 시도: 동의 전 조회(403).
    - 사유: 동의 후에 `/me/drive`를 다시 조회하지 않음.
    - 다음 방법: 읽기 범위를 동의한 토큰으로 `GET /me/drive`를 다시 실행.
- **오전의 "기본 문서 라이브러리를 찾을 수 없음" 오류가 사라진 이유**
    - 시도: 시간을 두고 같은 화면을 다시 열기(오후에 정상).
    - 사유: 다시 열었을 때 이미 정상이어서 오류 상태를 더 확인할 수 없음. 프로비저닝 지연으로 추정할 뿐입니다.
    - 다음 방법: 같은 오류가 다시 나면 발생 시각과 화면을 남기고 시간 간격을 두고 재시도.
- **실제 녹화와 1:1 채팅 파일이 이 폴더에 저장되는지**
    - 시도: 폴더 존재 확인.
    - 사유: 녹화와 파일 전송은 마이크, 카메라와 두 번째 사용자가 필요한 조작이라 수행하지 않음.
    - 다음 방법: 시험 사용자와 함께 회의를 열어 녹화하고 파일을 보냄.

</details>

### 5. 관련 글

- [Teams 저장 구조: 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }})
- [Cloud Shell에서 Graph 호출: 되는 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **조회**: 관리자 OneDrive가 열림. My files에 Meetings, Microsoft Copilot Chat Files, Recordings 폴더(모두 0개)
    - 출처: OneDrive 웹
- **조회**: 오전에 "기본 문서 라이브러리를 찾을 수 없음" 오류, Graph `/me/drive` HTTP 403
    - 출처: OneDrive 웹, Cloud Shell(Graph)
- **문서**: 회의 녹화 저장 위치(일반 회의=주최자 OneDrive, 채널 회의=팀 사이트 Recordings)
    - 출처: [Teams meeting recording and transcript storage and permissions](https://learn.microsoft.com/microsoftteams/tmr-meeting-recording-change#recording-storage)
- **문서**: 1:1·회의 채팅과 녹화의 저장 위치
    - 출처: [Finding content in Microsoft Teams in eDiscovery](https://learn.microsoft.com/purview/edisc-search-teams#where-teams-content-is-stored)
- **확인 불가**: 동의 후 `/me/drive` 결과 / 오류가 사라진 이유(프로비저닝 지연으로 추정) / 녹화·채팅 파일의 실제 저장
    - 시도, 사유, 다음 방법은 4절 '확인 불가로 남은 것'

</details>
