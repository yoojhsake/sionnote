---
title: "[Troubleshooting] 비공개·공유 채널 파일이 403: 멤버십 문제인가, 토큰 범위 문제인가"
date: 2026-10-23 10:20:00 +0900
last_modified_at: 2026-10-27 10:00:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 1
tags: [Teams, SharePoint, Graph, "403", 비공개 채널, 공유 채널, 토큰 범위]
excerpt: "비공개·공유 채널만 403이 났습니다. 멤버십이 아니라 토큰 범위 부족이었고, 읽기 범위를 동의하자 200 OK로 열렸습니다."
---

표준 채널에는 Graph로 파일이 올라가는데 비공개·공유 채널만 403이 났습니다. 멤버십이 아니라 토큰의 파일·사이트 범위가 원인이었고, Files.Read.All과 Sites.Read.All을 동의하자 두 채널 사이트 모두 200 OK로 파일 목록이 돌아왔습니다.

## 요약

- 관리자가 채널 소유자이고 화면에서도 열려 멤버십 문제는 아니었음
- 채널 403은 화면 접근과 멤버십을 본 뒤 토큰 범위 순으로 나눠 보면 됨
- 읽기만 확인했으니 업로드 성공은 따로 시험해야 함

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 사이트 주소도 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

- Graph 업로드가 표준 채널은 성공, 비공개·공유 채널은 업로드·폴더 읽기 모두 403(accessDenied 계열)이었습니다.

| 채널 유형 | 업로드 | 폴더 읽기 | 새 파일 생성 |
|---|---|---|---|
| 표준 | 성공 | 성공 | 생성됨 |
| 비공개 | HTTP 403 | HTTP 403 | 생성 안 됨 |
| 공유 | HTTP 403 | HTTP 403 | 생성 안 됨 |

10/22에 생긴 두 채널의 시험 파일이 화면에 남아 있는 현상은 [별도 글]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})에서 다룹니다.

### 2. 원인 및 분석

비공개·공유 채널은 별도 사이트를 쓰고 비공개 채널 사이트는 구성원만 접근합니다(문서: Private channels, Shared channels). 업로드(`PUT .../content`)에는 Files.ReadWrite, Files.ReadWrite.All, Sites.ReadWrite.All 중 하나가 필요하고(문서: driveItem 업로드), Group.ReadWrite.All은 하위 호환용으로만 지원됩니다(문서: Get filesFolder). 화면 접근 → 멤버십 → 토큰 범위 순으로 나눠 봤습니다.

| 가설 | 기대값 | 실제값 |
|---|---|---|
| 1. 사용자에게 채널 사이트 권한이 없다 | 화면에서 막힘 | SharePoint 화면에서 두 사이트 Documents가 열림 |
| 2. 관리자가 채널 구성원이 아니다 | 구성원 아님 | 네 채널(General 포함) 모두 구성원 1명(관리자, owner) |
| 3. 토큰에 파일·사이트 범위가 없다 | scp에 Files.*·Sites.* | 없음(Group.ReadWrite.All 등만 있음) |
| 3 증명. 범위를 더해 같은 요청 | 403 → 200 | 동의 전 accessDenied / 동의 후 두 사이트 모두 200 OK |

Files 범위 토큰은 `az login` 장치 코드 로그인이 오류 530035로 막혀 Graph 탐색기(브라우저 로그인)로 얻었습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 9장)</summary>

#### 가설 나누기

403의 원인을 세 갈래로 나누고, 사용자 쪽부터 보고 토큰 쪽으로 좁혀 갔습니다. 모두 읽기 전용 확인입니다.

- **가설 1. 사용자가 그 채널 사이트에 권한이 없다**
    - 확인 방법: SharePoint 화면(GUI)에서 두 채널 사이트의 Documents가 열리는지
    - 판단: 열리면 사용자 권한 문제가 아님
- **가설 2. 관리자 계정이 채널 구성원이 아니다**
    - 확인 방법: 채널 구성원 목록 조회
    - 판단: 구성원(owner)이면 멤버십 문제가 아님
- **가설 3. Graph 토큰에 파일·사이트 범위가 없다**
    - 확인 방법: 토큰의 허용 범위(scp) 확인, 범위를 더한 토큰으로 같은 요청 비교
    - 판단: 범위가 없고, 더했을 때 열리면 토큰 범위 문제

배경으로, 문서는 비공개 채널과 공유 채널이 팀 사이트와 별도의 사이트를 쓰고 비공개 채널 사이트에는 채널 구성원만 접근할 수 있다고 설명합니다(문서: Private channels, Shared channels). 그래서 표준 채널과 달리 이 두 유형에서만 막히는 것이 자연스러운지부터 살폈습니다.

#### 증상 재현: 업로드와 폴더 읽기 (조회)

채널의 파일 폴더 `driveId`와 `itemId`를 구해 `PUT .../content`로 올리는 방식입니다(이 방법 자체는 [채널 경로 업로드 400 글]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }})에 있습니다).

아래 공통 준비 코드는 이 글과 관련 글의 모든 스크립트 앞에서 한 번 실행합니다. Cloud Shell 세션이 유지되는 동안 변수가 남습니다. 팀 이름 Practice-Team-01은 시험용으로 만든 팀입니다.

```powershell
# 공통(1~5줄): Cloud Shell(PowerShell)의 Azure 로그인 세션으로 Graph 토큰을 받아 호출 (조회·시험용)
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$tid = (Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Where-Object displayName -eq 'Practice-Team-01' | Select-Object -ExpandProperty id
$ch  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/allChannels").value
```

업로드 시험 스크립트입니다.

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  $u  = "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id):/zz-test.txt:/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'zz-test' | Out-Null; "UPLOAD OK zz-test.txt -> $($c.displayName)" }
  catch { "UPLOAD $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase)) $(($_.ErrorDetails.Message | ConvertFrom-Json).error.code)" }
}
```

*이 스크립트는 채널마다 파일 폴더의 driveId·itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다(Graph 문서의 업로드 방식). 같은 파일명으로 다시 올리면 표준 채널과 General의 기존 zz-test.txt가 덮어써집니다.*

![채널별 업로드 결과]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 1. Cloud Shell(PowerShell)에서 세 채널과 General에 시험 파일을 올린 결과(위쪽은 실행한 명령, 아래는 출력). ch-standard와 General은 "UPLOAD OK zz-test.txt", 비공개(ch-private)와 공유(ch-shared)는 "403 (Forbidden) accessDenied"가 출력됩니다. 프롬프트의 계정 부분은 가렸습니다.*

업로드만 막힌 것인지 알아보려고 폴더 읽기도 같은 방식으로 시험했습니다.

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  try { $r = (Invoke-RestMethod -Headers $h -Uri "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id)/children").value.name -join ', '; "READ $($c.displayName): $r" }
  catch { "READ $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
}
```

![채널 폴더 읽기 결과]({{ "/assets/images/2026/10/m13-2-read-403.png" | relative_url }})
*그림 2. 폴더 읽기 결과(위쪽은 실행한 명령). 표준 채널(ch-standard)은 파일 목록 D3-test-ch-standard.txt, zz-test.txt, zz-test2-ch-standard.txt, zz-x.txt가 나오고, 비공개·공유 채널은 둘 다 "READ … 403 (Forbidden)", General은 zz-test.txt, zz-x.txt가 나옵니다. zz-x.txt는 제가 채널 폴더 경로를 잘못 지정해 시험하다 생긴 파일로, 읽기 결과에서 ch-standard와 General 폴더 목록 양쪽에 보였습니다. 생긴 정확한 위치는 이 글에서 확정하지 않았고 정리 목록에 넣었습니다.*

#### 화면에서는 열린다 (조회)

같은 관리자 계정으로 SharePoint 화면에서 비공개·공유 채널 사이트의 Documents 목록을 열었습니다. 앞서 올린 시험 파일(D3-test-ch-private.txt, D3-test-ch-shared.txt)이 보였습니다. 사용자의 권한이나 멤버십 문제라면 화면에서도 막혔을 것입니다.

![비공개 채널 사이트의 문서 목록(SharePoint 화면)]({{ "/assets/images/2026/10/m22-4-gui-private-channel-files.png" | relative_url }})
*그림 3. 비공개 채널 사이트의 Documents 화면. 시험 파일 D3-test-ch-private.txt가 보입니다(5일 전 = 10/22, 화면의 "5일 전"은 촬영 시점 기준 상대 표기). 수정자 이름은 가렸습니다.*

![공유 채널 사이트의 문서 목록(SharePoint 화면)]({{ "/assets/images/2026/10/m22-5-gui-shared-channel-files.png" | relative_url }})
*그림 4. 공유 채널 사이트의 Documents 화면. 시험 파일 D3-test-ch-shared.txt가 보입니다. 수정자 이름은 가렸습니다.*

#### 채널 구성원 여부 (조회)

관리자 계정이 네 채널의 구성원인지 Graph로 읽었습니다. 네 채널(General과 ch-standard, ch-private, ch-shared) 모두 구성원은 1명이고, 그 한 명이 관리자 계정이며 역할은 owner였습니다.

문서는 비공개 채널 사이트에 채널 구성원만 접근할 수 있다고 설명하지만(문서: Private channels), 이 계정은 이미 구성원이니 **멤버십 때문은 아닙니다.**

```powershell
$myid = (Invoke-RestMethod -Headers $h -Uri "$B/me").id
foreach ($c in $ch) {
  $m  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/members" -StatusCodeVariable sc).value
  $me = $m | Where-Object userId -eq $myid
  "$($c.displayName): http=$sc members=$($m.Count) admin_is_member=$([bool]$me) roles=$($me.roles -join ',')"
}
```

![채널별 구성원 확인 결과]({{ "/assets/images/2026/10/m13-4-channel-members.png" | relative_url }})
*그림 5. 채널별 구성원 조회 결과(위쪽은 실행한 명령). 네 채널(General 포함) 모두 http=200, members=1, admin_is_member=True, roles=owner로 관리자 계정이 소유자 구성원입니다. 계정 부분은 가렸습니다.*

#### 토큰의 허용 범위 (조회)

업로드에 쓴 토큰을 해독해 허용된 범위(scp)만 출력했습니다. 토큰 본문은 화면에 출력하지 않고 payload의 scp 등만 읽습니다.

```powershell
# 토큰 본문은 출력하지 않고 범위(scp)·앱 ID·주체 유형만 읽는다
$p = $tk.Split('.')[1].Replace('-','+').Replace('_','/'); while ($p.Length % 4) { $p += '=' }
$c = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p)) | ConvertFrom-Json
"SCP:   $($c.scp)"; "APPID: $($c.appid)"; "IDTYP: $($c.idtyp)"
```

범위는 AppCatalog.Read.All, AuditLog.Read.All, Channel.Create, Channel.ReadBasic.All, ChannelMember.ReadWrite.All, Directory.ReadWrite.All, Group.ReadWrite.All, IdentityProvider.ReadWrite.All, Team.Create, Team.ReadBasic.All, TeamSettings.ReadWrite.All, User.Invite.All 등이었습니다. **Files.* 와 Sites.* 범위는 없었습니다.** Cloud Shell에서 `az account get-access-token`으로 받은 Azure CLI 토큰도 2026-11-04에 같은 방식으로 풀어 보니 appid와 scp가 이 토큰과 같았습니다([Cloud Shell Graph 토큰 글]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})의 그림 4). 내 PC의 `az login` 토큰은 비교하지 않았습니다.

![토큰 범위 확인 결과]({{ "/assets/images/2026/10/m13-3-token-scope.png" | relative_url }})
*그림 6. 토큰 범위 출력(SCP). Files.ReadWrite나 Sites.ReadWrite.All 같은 파일·사이트 범위가 목록에 없습니다. APPID는 Cloud Shell이 쓰는 앱의 ID, IDTYP=user는 사용자 위임 토큰이라는 뜻입니다. 토큰 본문은 출력하지 않았습니다.*

여기까지는 "범위가 없다"는 사실과 "그래서 막힌다"는 추정이 겹친 상태입니다. 범위를 더한 토큰으로 같은 요청을 해 보는 것이 마지막 증명입니다.

#### Files 범위 토큰을 얻으려던 시도 (막힘)

Files.ReadWrite.All 범위 토큰을 얻으려고 두 가지를 시도했습니다.

첫 번째는 Cloud Shell의 `az login --scope https://graph.microsoft.com/Files.ReadWrite.All --use-device-code`였습니다. 장치 코드를 입력하고 이미 로그인된 계정을 골랐더니 오류 코드 530035, "이에 대한 액세스 권한이 없습니다"로 막혔습니다. 화면에는 앱 이름 Microsoft Azure CLI, 디바이스 상태 Unregistered가 표시됐습니다. 사실 코드를 처음에 잘못 읽어(G와 Q 혼동) 두 번 거절됐고, 코드를 글자별 숫자로 출력해 정확히 읽은 뒤에야 위 결과가 나왔습니다.

두 번째는 Graph 탐색기였는데, 처음에는 로그인 버튼을 눌러도 로그인 창이 팝업으로 열리지 않아(팝업 차단) 진행하지 못했습니다.

![az login 장치 코드 로그인 530035 오류]({{ "/assets/images/2026/10/530035-azcli.png" | relative_url }})
*그림 7. az login 장치 코드 로그인이 오류 530035로 막힌 화면. 시험한 명령은 Files.ReadWrite.All 범위를 붙인 것이었고, 이 그림은 범위 없이 `az login --use-device-code`만 실행해 선명하게 다시 찍은 것입니다(같은 앱 Microsoft Azure CLI, 같은 오류 코드 530035). 계정, 요청 ID, 접속 IP는 가렸습니다.*

같은 530035가 Exchange PowerShell 로그인에서도 났으므로([530035 장치 코드 로그인 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})), 이 테넌트는 포털 밖 클라이언트 로그인을 전반적으로 막고 있는 것으로 보입니다. 이 시도로 바뀐 설정이나 권한은 없습니다(로그인이 실패해 동의도 부여되지 않았습니다).

그래서 마지막 증명은 장치 코드 로그인을 쓰지 않는 방법, 브라우저 로그인을 쓰는 Graph 탐색기로 바꿨습니다. 요청은 읽기만 하고 파일을 올리거나 지우지 않았습니다.

#### 동의 전과 후 비교 (Graph 탐색기, 조회)

동의 전에는 사이트 조회(`GET /sites/{호스트}:/sites/Practice-Team-01-ch-private`)는 200인데 파일 목록(`GET /sites/{site-id}/drive/root/children`)은 accessDenied였습니다. 사이트 정보는 읽히지만 파일은 못 읽는 상태로, 토큰에 Files.* 와 Sites.* 범위가 없던 것(위 "토큰의 허용 범위")과 일치합니다.

동의 후에는 Graph 탐색기의 "권한 수정(Modify permissions)" 탭에서 Files.Read.All과 Sites.Read.All을 직접 동의한 뒤 같은 요청을 다시 실행했습니다. 두 채널 사이트 모두 200 OK로 파일 목록이 반환됐고 시험 파일이 그대로 보였습니다.

![동의 후 비공개 채널 사이트 파일 목록 200]({{ "/assets/images/2026/10/m22-2-private-channel-files-200.png" | relative_url }})
*그림 8. 동의 후 비공개 채널 사이트 `drive/root/children` 조회가 200 OK. D3-test-ch-private.txt(마지막 수정 2026-10-22)가 반환됩니다. 요청 주소와 사이트·테넌트 식별자는 가렸습니다.*

![동의 후 공유 채널 사이트 파일 목록 200]({{ "/assets/images/2026/10/m22-3-shared-channel-files-200.png" | relative_url }})
*그림 9. 동의 후 공유 채널 사이트 `drive/root/children` 조회가 200 OK. D3-test-ch-shared.txt(마지막 수정 2026-10-22)가 반환됩니다. 요청 주소와 식별자는 가렸습니다.*

같은 계정, 같은 요청에서 달라진 것은 토큰의 범위뿐입니다. 읽기 쪽 403은 멤버십이나 사용자 권한이 아니라 **토큰의 파일·사이트 읽기 범위 부족** 때문이었습니다.

#### 확인하지 못한 것

- **응답은 403인데 파일이 생긴 현상의 원인**: 확인 불가입니다.
    - 시도: 같은 방식으로 다시 올려 보기.
    - 사유: 이번에는 새 파일이 생기지 않았고, 처음 요청·응답을 저장해 두지 않아 대조할 수 없음.
    - 다음 방법: 요청과 응답 전체를 파일로 저장하면서 재현([해당 글]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})).

</details>

### 3. 결론

Cloud Shell 토큰에 Files.*·Sites.* 범위 없음 → 채널 전용 사이트 드라이브 쓰기·읽기 403 → 화면과 멤버십은 정상

Files.Read.All·Sites.Read.All 동의 후 같은 요청이 200 OK가 됐고, 업로드 성공은 따로 시험해야 합니다. 403인데 파일이 생긴 원인은 확인 불가입니다(시도·사유는 확인 과정 "확인하지 못한 것").

### 4. 권고방안

1. 조치: 채널 파일 작업은 Files.*·Sites.* 범위가 있는 토큰으로 합니다(Graph 탐색기 "권한 수정(Modify permissions)" 탭에서 동의).
2. 확인: 채널 사이트 `drive/root/children`이 200 OK이고 accessDenied가 없으면 됩니다. 업로드는 응답 코드와 저장 위치를 둘 다 보고, 재현 시 요청·응답을 파일로 저장합니다.
3. 하지 말 것: 팀 사이트(그룹 드라이브)가 열린다고 채널 전용 사이트도 열린다고 보지 않습니다.
4. 원복·정리: az login 시도는 바뀐 설정이 없습니다. 동의한 범위는 Entra 관리 센터 엔터프라이즈 애플리케이션에서 철회할 수 있습니다. 표준 채널과 General의 `zz-test*.txt`는 팀 삭제 때 지우고, 채널 사이트를 정리 목록에 넣습니다.

관련 글: [채널 경로 업로드 400]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }}) · [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) · [응답은 403인데 파일이 생김]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }}) · [Exchange 장치 코드 로그인 530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}) · [Teams 저장 구조: 채널 유형별 파일 위치]({{ "/m365/d3-teams-storage/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- **문서**: 비공개·공유 채널은 별도 사이트
    - 출처: [Shared channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/shared-channels)
- **조회**: 표준 성공, 비공개·공유 403, 폴더 읽기 403, 앞서 올린 파일 존재
    - 출처: Cloud Shell(Graph), SharePoint
- **조회**: 네 채널(General 포함) 모두 관리자 계정이 owner 구성원 / 토큰 scp에 Files.*·Sites.* 없음
    - 출처: Cloud Shell(Graph)
- **조회**: 화면에서는 두 채널 사이트 문서 목록이 열림 / 읽기 범위 동의 전 파일 목록 accessDenied, 동의 후 200(그림 3~4, 8~9)
    - 출처: SharePoint 화면, Graph 탐색기
- **시도**: Files 범위 az login 장치 코드 로그인에서 오류 530035(그림 7), Graph 탐색기 로그인 팝업 차단
    - 출처: 로그인 화면
- **문서**: 업로드·폴더 정보 조회에 필요한 Graph 권한
    - 출처: [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0), [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0)
- **문서**: 비공개 채널은 별도 사이트이고 채널 구성원만 접근
    - 출처: [Private channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/private-channels#private-channel-sharepoint-sites)

</details>
