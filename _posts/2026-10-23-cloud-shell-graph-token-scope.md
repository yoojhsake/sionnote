---
title: "[Troubleshooting] Cloud Shell 토큰으로 Graph를 호출하면 되는 것과 403이 나는 것이 갈림"
date: 2026-10-23 10:30:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 1
tags: [Cloud Shell, Graph, 토큰, "403", 토큰 범위]
excerpt: "같은 Cloud Shell 토큰인데 목록은 읽히고 파일은 403, 정책 목록도 403. 파일 403은 Files·Sites 범위가 없어서였고, 정책은 GUI로 읽었다"
---

같은 Cloud Shell 토큰으로 팀, 사용자, 채널 목록은 잘 읽히는데 채널 파일 폴더, 내 OneDrive, 조건부 액세스 정책 목록만 403이 납니다. 채널 파일 폴더와 내 OneDrive 403은 토큰에 Files.\*·Sites.\* 범위가 없었기 때문이고, 조건부 액세스 정책 목록 403은 scp에 Policy.Read.All이 없는 것과 일치합니다(문서: 최소 권한 Policy.Read.All). 설정을 바꾸지 않고 되는 호출은 이 토큰으로, 안 되는 항목은 화면(GUI)으로 읽었습니다.

## 요약

- 이 토큰은 목록 같은 읽기 조회에는 쓸 만하지만 파일 호출은 403이 남
- 403이 나면 설정을 바꾸지 말고 GUI로 읽거나 범위 동의를 승인받으면 됨
- Graph 탐색기(Files·Sites 동의가 되어 있던 토큰)로 `/me/drive`를 조회하면 200으로 열림(2026-11-04 확인)

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면과 PowerShell에서 읽었고, 토큰도 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

Cloud Shell(PowerShell)의 Azure 세션 토큰(`Get-AzAccessToken`, 별도 로그인·설정 변경 없음)으로 Graph를 호출하니 결과가 갈렸습니다.

- 성공: 내가 가입한 팀 목록(`joinedTeams`), 사용자 목록, 서비스 사용자 목록, 팀 > 채널 목록(`allChannels` 포함), 표준 채널 파일 폴더 정보
- HTTP 403: 비공개·공유 채널 파일 폴더 정보([채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})), 내 OneDrive(`/me/drive`), 조건부 액세스 정책 목록(scp에 Policy.Read.All 없음, 그림 2)

![Graph로 읽은 팀 목록]({{ "/assets/images/2026/10/m14-2-group-list.png" | relative_url }})
*그림 1. 위쪽 세 줄은 토큰, 헤더, 주소 변수를 만드는 줄이고, 네 번째 줄이 `joinedTeams`를 호출해 팀 표(displayName, id)를 출력합니다. 호출이 성공해 팀 8개가 나옵니다. 테넌트 이름과 같은 팀·다른 조직 이름 팀의 이름, id 열 전체, 계정 이름은 가렸습니다.*

```powershell
# 1~3줄: 토큰·헤더·주소 변수 (그림 1의 위쪽 세 줄)
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
(Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Select-Object displayName,id | Format-Table -AutoSize
```

### 2. 원인 및 분석

403을 대상 없음, 토큰 범위(scp), 읽기 역할로 나눠 봤습니다.

- `/me/drive`: "OneDrive 없음" 추정 / OneDrive 웹에 Meetings, Recordings 폴더 있음. scp에 Files.*·Sites.* 없음
- Files.Read.All, Sites.Read.All 동의 후(Graph 탐색기): 채널 전용 사이트 파일 목록 200
- 조건부 액세스 정책: 호출 403 / GUI로 0건

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 4장)</summary>

#### 403을 나눠 본 기준

1. **대상이 실제로 있는가**
    - 방법: 화면(GUI)에서 같은 대상을 열어 본다
    - 판단: 열리면 "대상 없음"이 아니라 권한이나 범위 쪽
2. **토큰에 필요한 범위가 있는가**
    - 방법: 토큰의 허용 범위(scp)만 출력
    - 판단: Files.*·Sites.*가 없으면 파일·사이트 계열은 403이 자연스러움
3. **계정에 읽기 역할이 있는가**
    - 방법: 화면(GUI)에서 같은 목록이 열리는지
    - 판단: 화면에서만 열리면 토큰이나 역할 문제

#### 시도와 결과

**`/me/drive`의 403.** 처음에는 관리자 계정에 OneDrive가 없어서 나는 오류라고 추정했습니다. 그런데 OneDrive 웹을 다시 열어 보니 OneDrive가 있었습니다(Meetings, Recordings 폴더 확인).

그래서 "대상이 없음"이라는 추정은 정정했고, 이 403은 토큰에 Files 범위가 없는 쪽으로 읽는 것이 맞아 보입니다. 같은 토큰의 범위를 읽어 보니 Files.*·Sites.* 가 없었고(조회, [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})), Graph 탐색기에서 Files.Read.All, Sites.Read.All을 동의하자 채널 전용 사이트의 파일 목록이 200으로 열렸습니다(조회). `/me/drive` 자체는 처음에는 동의 뒤에 다시 조회하지 않았다가, 2026-11-04에 Graph 탐색기에서 따로 조회했습니다(아래 그림 5).

![토큰의 허용 범위 목록을 출력한 Cloud Shell 화면]({{ "/assets/images/2026/10/m13-3-token-scope.png" | relative_url }})
*그림 2. 같은 토큰의 내용을 풀어 허용 범위(`SCP`)를 출력한 Cloud Shell 화면. AppCatalog, AuditLog, Channel, Directory, Group, Team 계열 범위는 있고 Files.\*·Sites.\* 범위는 보이지 않습니다. 계정이 보이던 프롬프트 부분은 가렸습니다.*

2026-11-04에 두 가지를 더 확인했습니다. 둘 다 위와 같은 샌드박스 관리자 계정이고 설정은 바꾸지 않았습니다.

- Cloud Shell에서 `az account get-access-token --resource https://graph.microsoft.com`로 받은 토큰과 `Get-AzAccessToken -ResourceUrl https://graph.microsoft.com`의 토큰을 같은 방식으로 풀어 보니 appid(`b677c290-…`)와 scp 목록이 같았습니다(그림 4). 따라서 Cloud Shell에서는 Azure CLI 토큰으로 바꿔도 Files·Sites 범위가 생기지 않습니다. 이 비교는 Cloud Shell 안에서만 한 것이고, 내 PC의 `az login` 토큰은 비교하지 않았습니다.
- Graph 탐색기에서 같은 계정으로 로그인한 상태(이전에 Files·Sites 동의를 해 둔 토큰)로 `GET /v1.0/me/drive?$select=driveType,name`을 조회하자 200이고 `name`은 OneDrive, `driveType`은 business였습니다(그림 5). 같은 계정의 같은 호출이 Cloud Shell 토큰에서는 403, 동의된 Graph 탐색기 토큰에서는 200이므로, 위의 "범위 문제" 해석과 맞습니다. 다만 Graph 탐색기 토큰의 scp를 이번에 풀어 보지는 않았습니다.

![Cloud Shell에서 Azure CLI 토큰과 Az PowerShell 토큰의 appid와 scp가 같게 출력된 화면]({{ "/assets/images/2026/10/m13-6-cli-vs-az-token-scp-1104.png" | relative_url }})

*그림 4. 2026-11-04 Cloud Shell 출력. 위: `az account get-access-token`(Azure CLI) 토큰, 아래: `Get-AzAccessToken` 토큰. 두 토큰 모두 appid가 같고 scp에는 AppCatalog, AuditLog, Channel, ChannelMember, Directory, Group, Team 계열 범위가 있으며 Files·Sites 범위는 없습니다. 프롬프트의 계정 이름은 짧게 바꿔 보이지 않게 했습니다.*

![Graph 탐색기에서 /me/drive 조회가 200 OK로 name OneDrive, driveType business를 돌려준 화면]({{ "/assets/images/2026/10/m13-7-me-drive-200-1104.png" | relative_url }})

*그림 5. 2026-11-04 Graph 탐색기에서 `GET /v1.0/me/drive?$select=driveType,name`을 조회한 결과(200 OK).*

**조건부 액세스 정책 목록의 403.** 정책 목록 호출은 scp에 Policy.Read.All이 없는 것(그림 2)과 일치하게 막혔습니다(문서: 최소 권한 Policy.Read.All). 화면(GUI)으로 대신 읽었더니 조건부 액세스 정책은 0건이었습니다.

![정책이 없을 때 표시되는 조건부 액세스 정책 화면]({{ "/assets/images/2026/10/ca-policies.png" | relative_url }})
*그림 3. Entra 관리 센터 > 조건부 액세스 > 정책. 정책 목록 대신 "조건부 액세스란 무엇인가요?" 안내와 예시만 나와 정책이 0건임을 보여 줍니다. 계정 표시는 가렸습니다.*

- **필요한 역할**: 문서에는 위임 최소 권한이 Policy.Read.All이고 허용 역할이 Security Reader, Global Reader, Conditional Access Administrator 등으로 나와 있습니다([List policies](https://learn.microsoft.com/graph/api/conditionalaccessroot-list-policies)). 이 계정에 어느 역할이 있는지는 조회하지 않았습니다(역할 부여는 하지 않음).

**로그인으로 범위를 넓히려는 시도.** Files.ReadWrite.All 범위를 붙인 `az login` 장치 코드 로그인은 오류 530035로 막혔습니다. 자세한 경과는 [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})과 [Exchange 장치 코드 로그인 530035 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})에 있습니다.

</details>

### 3. 결론

Cloud Shell 토큰에 Files.\*·Sites.\* 범위 없음 → 파일·사이트 계열 호출 403 → 목록 조회는 성공

정책 목록 403은 scp에 Policy.Read.All이 없는 것과 일치합니다(문서). 설정 변경이 없어 원복할 것은 없습니다. `/me/drive`는 Cloud Shell 토큰에서 403, 동의된 Graph 탐색기 토큰에서 200(11-04, 그림 5)이었고, 이 계정의 역할은 조회하지 않았습니다.

### 4. 권고방안

1. 조치: 이 토큰은 목록 조회에 쓰고, 파일·사이트 호출은 Files.*·Sites.* 범위를 동의한 토큰이나 GUI로 합니다.
2. 확인: 403이면 화면에서 대상이 열리는지부터 봅니다. 열리면 권한이나 범위 문제입니다.
3. 하지 말 것: 범위를 넓히려고 역할을 받거나 보안 설정을 바꾸지 않습니다(범위 동의는 별도 승인 항목).

관련 글: [비공개·공유 채널 파일 403: 멤버십인가 토큰 범위인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) · [채널 경로 업로드 400]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }}) · [Cloud Shell 세션 초기화·구문 오류]({{ "/m365/troubleshooting/cloud-shell-reset-and-syntax-error/" | relative_url }}) · [Exchange 장치 코드 로그인 530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- **조회**: 위 1절 목록의 호출 결과 (출처: Cloud Shell(Graph))
- **조회**: 토큰 scp에 Files.*·Sites.* 없음 (출처: Cloud Shell(Graph))
- **조회**: OneDrive 웹에서 Meetings, Recordings 폴더 확인 (출처: OneDrive 화면)
- **조회**: 조건부 액세스 정책 0건 (출처: 관리 화면(GUI))
- **조회**: Azure CLI 토큰과 Az PowerShell 토큰의 appid·scp 동일, `/me/drive` 200(Graph 탐색기) (출처: Cloud Shell, Graph 탐색기, 2026-11-04)
- **문서**: 정책 목록 호출의 최소 권한 Policy.Read.All, 허용 역할 (출처: [List policies](https://learn.microsoft.com/graph/api/conditionalaccessroot-list-policies))

</details>
