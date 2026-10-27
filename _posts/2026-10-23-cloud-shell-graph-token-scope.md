---
title: "[트러블슈팅] Cloud Shell 토큰으로 Graph를 호출하면 되는 것과 403이 나는 것이 갈림"
date: 2026-10-23 10:30:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 1
tags: [Cloud Shell, Graph, 토큰, "403", 토큰 범위]
excerpt: "Cloud Shell의 Azure 로그인으로 받은 Graph 토큰으로 읽은 것과 읽지 못한 것을 나누고, 보안 설정을 바꾸지 않고 쓸 수 있는 방법과 막혔을 때의 선택지를 정리한 기록"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 토큰·ID·계정은 게시하지 않았습니다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | 같은 토큰으로 팀·사용자·서비스 사용자·채널 목록은 읽히는데, 비공개·공유 채널 파일 폴더, 내 OneDrive, 조건부 액세스 정책 목록은 HTTP 403 |
| 원인 | Cloud Shell의 Azure 로그인 토큰에 **Files.\*·Sites.\* 범위가 없음**(조회). 조건부 액세스 정책은 읽기 권한이 부족 |
| 대처 | 보안 설정이나 역할을 바꾸지 않고, 되는 호출은 이 토큰으로 쓰고 안 되는 항목은 화면(GUI)으로 읽음 |
| 결과 | 조건부 액세스 정책은 GUI에서 0건 확인. 채널 파일은 읽기 범위를 동의한 토큰에서 열림([채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})) |

---

## 전체 기록

### 1. 증상

Azure Cloud Shell(PowerShell)에서 이미 로그인된 Azure 세션으로 Graph용 액세스 토큰을 받아(`Get-AzAccessToken`) Graph 주소를 호출했습니다. 별도 로그인이나 보안 설정 변경 없이 쓸 수 있는 방법이라 이번 실습에서 사용했습니다. 그런데 호출마다 결과가 갈렸습니다.

| 호출 | 결과 |
|---|---|
| 내가 가입한 팀 목록(`joinedTeams`) | 성공 |
| 사용자 목록 | 성공 |
| 서비스 사용자 목록 | 성공 |
| 팀 > 채널 목록(`allChannels` 포함) | 성공 |
| 채널 파일 폴더 정보 | 표준 채널 성공, 비공개·공유 채널은 403 ([채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})) |
| 내 OneDrive(`/me/drive`) | HTTP 403 |
| 조건부 액세스 정책 목록 | HTTP 403 (읽기 권한 부족) |

![Graph로 읽은 팀 목록]({{ "/assets/images/2026/10/m14-2-group-list.png" | relative_url }})
*그림 1. 위쪽 세 줄은 토큰·헤더·주소 변수를 만드는 줄이고, 네 번째 줄이 `joinedTeams`를 호출해 팀 표(displayName, id)를 출력한다. 호출이 성공해 팀 8개가 나온다. 테넌트 이름과 같은 팀·다른 조직 이름 팀의 이름, id 열 전체, 계정 이름은 가렸다.*

**실행한 스크립트**

```powershell
# 1~3줄: 토큰·헤더·주소 변수 (그림 1의 위쪽 세 줄)
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
(Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Select-Object displayName,id | Format-Table -AutoSize
```

### 2. 먼저 확인할 것

403이 났을 때 "권한 없음"과 "대상이 없음"을 구분합니다.

| 순서 | 확인 | 방법 | 판단 |
|---|---|---|---|
| 1 | 대상이 실제로 있는가 | 화면(GUI)에서 같은 대상을 열어 본다 | 열리면 "대상 없음"이 아니라 권한·범위 쪽 |
| 2 | 토큰에 필요한 범위가 있는가 | 토큰의 허용 범위(scp)만 출력 | Files.*·Sites.*가 없으면 파일·사이트 계열은 403이 자연스러움 |
| 3 | 계정에 읽기 역할이 있는가 | 화면(GUI)에서 같은 목록이 열리는지 | 화면에서만 열리면 토큰·역할 문제 |

### 3. 시도와 결과

**`/me/drive`의 403**: 처음에는 관리자 계정에 OneDrive가 없어서 나는 오류라고 추정했습니다. 그런데 OneDrive 웹을 다시 열었더니 **OneDrive가 존재했습니다**(Meetings·Recordings 폴더 확인). 그래서 "대상이 없음"이라는 추정은 정정하고, 이 403은 토큰에 Files 범위가 없는 쪽으로 읽는 것이 맞아 보입니다. 같은 토큰의 범위를 읽어 보니 Files.*·Sites.* 가 없었고(조회, [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})), Graph 탐색기에서 Files.Read.All·Sites.Read.All을 동의하자 채널 전용 사이트의 파일 목록이 200으로 열렸습니다(조회). 다만 `/me/drive` 자체는 범위를 동의한 뒤에 다시 조회하지 않았습니다.

- **확인 불가**: 동의 후 `/me/drive`가 열리는지. 시도: 동의 전 조회 → 403. 사유: 동의 후에 `/me/drive`를 다시 조회하지 않음. 다음 방법: 읽기 범위를 동의한 토큰으로 `GET /me/drive`를 한 번 더 실행.

**조건부 액세스 정책 목록의 403**: 정책 목록 호출이 읽기 권한 부족으로 막혔습니다. 읽기 역할이 부족한 항목은 화면(GUI)으로 대체해 읽었고, 조건부 액세스 정책은 GUI에서 0건이었습니다.

- **확인 불가**: 이 호출을 읽기만으로 하려면 필요한 최소 읽기 역할. 시도: 정책 목록 호출 → 403. 사유: 필요한 역할을 조회나 시험으로 가려내지 못함(역할 부여는 하지 않음). 다음 방법: Microsoft Learn의 해당 API 문서에서 필요한 권한·역할을 확인.

**로그인으로 범위를 넓히려는 시도**: Files.ReadWrite.All 범위를 붙인 `az login` 장치 코드 로그인은 오류 530035로 막혔습니다. 자세한 경과는 [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})과 [Exchange 장치 코드 로그인 530035 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})에 있습니다.

### 4. 대처·원복

- 토큰 범위를 넓히려고 역할을 부여받거나 보안 설정을 바꾸는 일은 하지 않았습니다. 별도 승인이 필요한 일이기 때문입니다. 그래서 원복할 변경도 없습니다.
- 읽기 역할이 부족한 항목은 화면(GUI)으로 대체해 읽었습니다.
- 채널 파일 업로드가 400으로 막힌 일은 경로 문제여서 [별도 글]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }})로 나눴습니다. 호출 묶음이 사라지는 문제는 [세션 초기화·구문 오류 글]({{ "/m365/troubleshooting/cloud-shell-reset-and-syntax-error/" | relative_url }})에 있습니다.

### 5. 운영에서는 이렇게 판단한다

- Cloud Shell의 Azure 로그인 토큰은 팀·사용자·서비스 사용자·채널 목록 같은 **읽기 조회**에는 쓸 만합니다. 파일·사이트(Files.*, Sites.*)가 필요한 호출은 이 토큰으로는 403이 날 수 있습니다.
- 403이 나면 "권한 없음"과 "대상이 없음"을 구분합니다. 화면에서 대상이 열리면 후자가 아닙니다.
- 읽기 역할이 부족한 항목은 보안 설정을 바꾸지 말고 GUI로 읽거나, 범위 동의를 별도 승인 항목으로 올립니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 조회 | 위 표의 호출 결과 | Cloud Shell(Graph) |
| 조회 | 토큰 scp에 Files.*·Sites.* 없음 | Cloud Shell(Graph) |
| 조회 | OneDrive 웹에서 Meetings·Recordings 폴더 확인 | OneDrive 화면 |
| 조회 | 조건부 액세스 정책 0건 | 관리 화면(GUI) |

관련 글: [비공개·공유 채널 파일 403 — 멤버십인가 토큰 범위인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) · [채널 경로 업로드 400]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }}) · [Cloud Shell 세션 초기화·구문 오류]({{ "/m365/troubleshooting/cloud-shell-reset-and-syntax-error/" | relative_url }}) · [Exchange 장치 코드 로그인 530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})
