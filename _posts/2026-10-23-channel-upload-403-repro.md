---
title: "[M365·Azure] 13 트러블슈팅 — Teams 채널 파일 업로드 403 재현 (표준·비공개·공유 채널 비교, 전체 기록)"
date: 2026-10-23 10:20:00 +0900
categories: [m365, troubleshooting]
tags: [Teams, SharePoint, Graph, "403", 비공개 채널, 공유 채널, 전체 기록]
excerpt: "10/22에 비공개·공유 채널 업로드가 403이었던 현상을 다시 시도한 결과와, 10/27에 읽기 범위를 동의해 원인(토큰 범위)을 확인한 기록"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트 도메인과 사이트 주소는 게시하지 않았고 사용자 이름은 적지 않았습니다.

## 1. 증상 (10/22)

비공개·공유 채널 폴더에 Graph로 시험 파일을 올렸을 때 응답이 403이었는데, SharePoint 화면에서 보면 파일이 있었습니다. 표준 채널은 정상 업로드였습니다. 자세한 상황은 [D3 글]({{ "/m365/readiness-d3-teams-storage/" | relative_url }})에 있습니다.

## 2. 10/23 재현

같은 방식(Cloud Shell에서 Graph로 채널의 파일 폴더 `driveId`·`itemId`를 구해 `PUT .../content`)으로 세 채널에 다시 올렸습니다.

| 채널 유형 | 업로드 | 폴더 읽기 | 새 파일 생성 |
|---|---|---|---|
| 표준 | 성공 | 성공 | 생성됨 |
| 비공개 | HTTP 403 | HTTP 403 | 생성 안 됨 |
| 공유 | HTTP 403 | HTTP 403 | 생성 안 됨 |

- 10/22에 만들어진 비공개·공유 채널의 시험 파일은 SharePoint 화면에서 여전히 있었습니다(조회).
- 응답 본문은 accessDenied 계열이었습니다.

![채널별 업로드 결과]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 1. Cloud Shell(PowerShell)에서 세 채널과 General에 시험 파일을 올린 결과(위쪽은 실행한 명령, 아래는 출력). ch-standard와 General은 "UPLOAD OK zz-test.txt", 비공개(ch-private)와 공유(ch-shared)는 "403 (Forbidden) accessDenied"가 출력된다. 프롬프트의 계정 부분은 가렸다.*

**실행한 스크립트** (아래 "공통 준비 코드"는 이 글의 모든 스크립트 앞에서 한 번 실행했고, Cloud Shell 세션이 유지되는 동안 변수가 남습니다. 팀 이름 Practice-Team-01은 시험용으로 만든 팀입니다.)

```powershell
# 공통(1~5줄): Cloud Shell(PowerShell)의 Azure 로그인 세션으로 Graph 토큰을 받아 호출 (조회·시험용)
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$tid = (Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Where-Object displayName -eq 'Practice-Team-01' | Select-Object -ExpandProperty id
$ch  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/allChannels").value
```

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  $u  = "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id):/zz-test.txt:/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'zz-test' | Out-Null; "UPLOAD OK zz-test.txt -> $($c.displayName)" }
  catch { "UPLOAD $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase)) $(($_.ErrorDetails.Message | ConvertFrom-Json).error.code)" }
}
```

*이 스크립트는 채널마다 파일 폴더의 driveId·itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다(Graph 문서의 업로드 방식). 같은 파일명으로 다시 올리면 표준 채널과 General의 기존 zz-test.txt가 덮어써집니다.*

![채널 폴더 읽기 결과]({{ "/assets/images/2026/10/m13-2-read-403.png" | relative_url }})
*그림 2. 폴더 읽기 결과(위쪽은 실행한 명령). 표준 채널(ch-standard)은 파일 목록 D3-test-ch-standard.txt, zz-test.txt, zz-test2-ch-standard.txt, zz-x.txt가 나오고, 비공개·공유 채널은 둘 다 "READ … 403 (Forbidden)", General은 zz-test.txt, zz-x.txt가 나온다. zz-x.txt는 제가 채널 폴더 경로를 잘못 지정해 시험하다 팀 문서함에 생긴 파일로 정리 목록에 넣었다.*

**실행한 스크립트**

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  try { $r = (Invoke-RestMethod -Headers $h -Uri "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id)/children").value.name -join ', '; "READ $($c.displayName): $r" }
  catch { "READ $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
}
```

## 3. 원인 확인: 멤버십인가, 권한 범위인가 (10/23 16:30경)

403의 원인으로 두 가지를 의심했고, 각각 읽기 전용 명령으로 확인했습니다.

**① 채널 구성원 여부**: 관리자 계정이 세 채널의 구성원인지 Graph로 읽었습니다. 세 채널(ch-standard, ch-private, ch-shared) 모두 구성원은 1명이고, 그 한 명이 관리자 계정이며 역할은 owner였습니다(조회). 문서는 비공개 채널 사이트에 채널 구성원만 접근할 수 있다고 설명하지만(문서: Private channels), 이 계정은 이미 구성원이라 **멤버십 때문은 아닙니다.**

![채널별 구성원 확인 결과]({{ "/assets/images/2026/10/m13-4-channel-members.png" | relative_url }})
*그림 3. 채널별 구성원 조회 결과(위쪽은 실행한 명령). 세 채널 모두 http=200, members=1, admin_is_member=True, roles=owner로 관리자 계정이 소유자 구성원이다. 채널 이름 중 General은 표준 채널이라 같은 결과다. 계정 부분은 가렸다.*

**실행한 스크립트**

```powershell
$myid = (Invoke-RestMethod -Headers $h -Uri "$B/me").id
foreach ($c in $ch) {
  $m  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/members" -StatusCodeVariable sc).value
  $me = $m | Where-Object userId -eq $myid
  "$($c.displayName): http=$sc members=$($m.Count) admin_is_member=$([bool]$me) roles=$($me.roles -join ',')"
}
```

**② Cloud Shell이 받은 Graph 토큰의 권한 범위**: 업로드에 쓴 토큰을 해독해 허용된 범위(scp)만 출력했습니다(토큰 본문은 출력하지 않음). 범위는 AppCatalog.Read.All, AuditLog.Read.All, Channel.Create, Channel.ReadBasic.All, ChannelMember.ReadWrite.All, Directory.ReadWrite.All, Group.ReadWrite.All, IdentityProvider.ReadWrite.All, Team.Create, Team.ReadBasic.All, TeamSettings.ReadWrite.All, User.Invite.All 등이었고, **Files.* 와 Sites.* 범위는 없었습니다**(조회). Azure CLI(`az account get-access-token`)로 받은 토큰도 같은 앱·같은 범위였습니다.

![토큰 범위 확인 결과]({{ "/assets/images/2026/10/m13-3-token-scope.png" | relative_url }})
*그림 4. 토큰 범위 출력(SCP). Files.ReadWrite나 Sites.ReadWrite.All 같은 파일·사이트 범위가 목록에 없다. APPID는 Cloud Shell이 쓰는 앱의 ID, IDTYP=user는 사용자 위임 토큰이라는 뜻이다. 토큰 본문은 출력하지 않았다.*

**실행한 스크립트** (토큰 본문은 화면에 출력하지 않고 payload의 scp 등만 읽습니다)

```powershell
# 토큰 본문은 출력하지 않고 범위(scp)·앱 ID·주체 유형만 읽는다
$p = $tk.Split('.')[1].Replace('-','+').Replace('_','/'); while ($p.Length % 4) { $p += '=' }
$c = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p)) | ConvertFrom-Json
"SCP:   $($c.scp)"; "APPID: $($c.appid)"; "IDTYP: $($c.idtyp)"
```

문서에 따르면 파일 업로드(`PUT .../content`)에는 Files.ReadWrite, Files.ReadWrite.All, Sites.ReadWrite.All 중 하나가 필요합니다(문서: driveItem 업로드). Group.ReadWrite.All은 하위 호환용으로만 지원되고(문서: Get filesFolder), 팀 사이트처럼 **그룹에 연결된 드라이브**는 이 범위로 열렸지만 비공개·공유 채널의 **별도 사이트 드라이브**는 열리지 않는 것으로 보입니다.

그래서 표준 채널만 성공하고 비공개·공유 채널은 쓰기·읽기 모두 403이 난 결과와 맞습니다.

**③ Files 권한이 있는 토큰으로 직접 확인하기 (10/23 16:46경, 실패)**: 원인을 확정하려면 Files.ReadWrite.All 범위 토큰이 필요해서 두 가지를 시도했습니다.

- Graph 탐색기(Graph Explorer): 로그인 버튼을 눌렀지만 로그인 창이 팝업으로 열리지 않아(팝업 차단) 진행하지 못했습니다. 이후 10/27에 이어서 시험했습니다(§7).
- Cloud Shell의 `az login --scope https://graph.microsoft.com/Files.ReadWrite.All --use-device-code`: 장치 코드를 입력하고 이미 로그인된 계정을 골랐더니 **오류 코드 530035, "이에 대한 액세스 권한이 없습니다"** 로 막혔습니다. 화면에는 앱 이름 Microsoft Azure CLI, 디바이스 상태 Unregistered가 표시됐습니다. 코드를 처음에 잘못 읽어(G와 Q 혼동) 두 번 거절됐고, 코드를 글자별 숫자로 출력해 정확히 읽은 뒤에 위 결과가 나왔습니다.

![az login 장치 코드 로그인 530035 오류]({{ "/assets/images/2026/10/530035-azcli.png" | relative_url }})
*그림 5. az login 장치 코드 로그인이 오류 530035로 막힌 화면. 10/23에는 Files.ReadWrite.All 범위를 붙인 명령으로 막혔고, 이 그림은 10/24 01:22경 선명하게 다시 찍은 것으로 범위 없이 `az login --use-device-code`만 실행했다(같은 앱 Microsoft Azure CLI, 같은 오류 코드 530035). 계정, 요청 ID, 접속 IP는 가렸다.*

같은 530035가 Exchange PowerShell 로그인에서도 났으므로(관련 글: 530035 장치 코드 로그인), 이 테넌트는 포털 밖 클라이언트 로그인을 전반적으로 막고 있는 것으로 보입니다.

그래서 채널 403의 마지막 증명은 장치 코드 로그인을 쓰지 않는 방법으로 바꿨습니다(§7). 이번 시도로 바뀐 설정이나 권한은 없습니다(로그인이 실패해 동의도 부여되지 않았습니다). 같은 문제는 10/27에 Graph 탐색기(브라우저 로그인)로 우회해 확인했습니다(§7).

## 4. 해석

- **결론(가장 가능성이 높은 원인)**: 멤버십이 아니라 **토큰의 권한 범위 부족**입니다. 관리자 계정은 세 채널의 owner인데도 Files/Sites 범위가 없는 토큰으로는 채널 전용 사이트 드라이브에 접근할 수 없습니다.
- **아직 증명하지 못한 부분**: Files.ReadWrite.All 범위가 있는 토큰으로 같은 업로드를 해 성공하는 것을 직접 보지는 못했습니다. 그 토큰을 얻으려고 Graph 탐색기와 `az login` 장치 코드 로그인을 시도했으나 각각 팝업 차단, 530035로 막혔습니다(§3-③). 이후 10/27에 Graph 탐색기에서 읽기 범위를 동의하고 다시 조회해 읽기 쪽 원인은 확인했습니다(§7).
- **확인 불가**: 10/22의 "403인데 파일이 생긴" 현상의 원인. 시도: 10/23 같은 방식 재현. 사유: 이번에는 새 파일이 생기지 않았고, 10/22의 요청·응답을 저장해 두지 않아 대조할 수 없습니다.

## 5. 다음에 할 일 / 운영 판단

1. 재현할 때는 **요청과 응답 전체를 파일로 저장**합니다(이번 일의 교훈).
2. 업로드 성공 여부는 응답 코드만으로 판단하지 않고, 코드와 실제 저장 위치를 둘 다 확인합니다.
3. 읽기 쪽은 10/27에 범위를 동의한 토큰으로 확인했습니다(§7). 쓰기(업로드) 성공은 Files.ReadWrite.All 범위로 별도 확인할 항목이며 아직 하지 않았습니다. 채널 구성원 문제는 위에서 배제했습니다.
4. 정리(삭제)할 때 채널 사이트가 따로 있다는 점을 목록에 넣습니다. 표준 채널과 General에는 이번 시험 파일 `zz-test*.txt`도 남아 있어 팀 삭제 때 함께 지웁니다.

## 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 비공개·공유 채널은 별도 사이트 | [Shared channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/shared-channels) |
| 조회 | 표준 성공, 비공개·공유 403, 폴더 읽기 403, 10/22 파일 존재 | Cloud Shell(Graph), SharePoint |
| 조회 | 세 채널 모두 관리자 계정이 owner 구성원 / 토큰 scp에 Files.*·Sites.* 없음 | Cloud Shell(Graph) |
| 조회 | 화면에서는 두 채널 사이트 문서 목록이 열림 / 읽기 범위 동의 전 파일 목록 accessDenied, 동의 후 200(그림 6~9) | SharePoint 화면, Graph 탐색기 |
| 시도 | Files 범위 az login 장치 코드 로그인 → 오류 530035(그림 5), Graph 탐색기 로그인 팝업 차단 | 로그인 화면 |
| 문서 | 업로드·폴더 정보 조회에 필요한 Graph 권한 | [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0), [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0) |
| 문서 | 비공개 채널은 별도 사이트이고 채널 구성원만 접근 | [Private channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/private-channels#private-channel-sharepoint-sites) |

## 7. 10/27 추가 확인: 읽기 범위를 동의하면 두 채널 사이트가 열린다

10/23까지는 "Files/Sites 범위가 없는 토큰이라 안 열린다"는 추정이었습니다. 10/27에는 같은 관리자 계정으로 먼저 화면(SharePoint)에서 두 채널 사이트를 열어 보고, 이어서 Graph 탐색기에서 **읽기 범위를 동의하기 전과 후**의 결과를 비교했습니다. 모두 읽기만 했고 파일을 올리거나 지우지 않았습니다.

**① 화면에서는 열림 (조회)**: 관리자 계정으로 비공개·공유 채널 사이트의 Documents 목록이 열리고 10/22에 올린 시험 파일(D3-test-ch-private.txt, D3-test-ch-shared.txt)이 보였습니다. 사용자의 권한이나 멤버십 문제라면 화면에서도 막혔을 것입니다.

![비공개 채널 사이트의 문서 목록(SharePoint 화면)]({{ "/assets/images/2026/10/m22-4-gui-private-channel-files.png" | relative_url }})
*그림 6. 비공개 채널 사이트의 Documents 화면. 시험 파일 D3-test-ch-private.txt가 보인다(5일 전 = 10/22). 수정자 이름은 가렸다.*

![공유 채널 사이트의 문서 목록(SharePoint 화면)]({{ "/assets/images/2026/10/m22-5-gui-shared-channel-files.png" | relative_url }})
*그림 7. 공유 채널 사이트의 Documents 화면. 시험 파일 D3-test-ch-shared.txt가 보인다. 수정자 이름은 가렸다.*

**② 같은 계정의 Graph 토큰, 동의 전 (조회)**: 사이트 조회(`GET /sites/{호스트}:/sites/Practice-Team-01-ch-private`)는 200인데 파일 목록(`GET /sites/{site-id}/drive/root/children`)은 **accessDenied**였습니다. 사이트 정보는 읽히지만 파일은 못 읽는 상태로, 10/23 토큰에 Files.*·Sites.* 범위가 없던 것과 일치합니다.

**③ 읽기 범위 동의 후 (조회)**: Graph 탐색기의 "권한 수정(Modify permissions)" 탭에서 **Files.Read.All**과 **Sites.Read.All**을 직접 동의한 뒤 같은 요청을 다시 실행했더니 두 채널 사이트 모두 **200 OK**로 파일 목록이 반환됐고 10/22 시험 파일이 그대로 보였습니다.

![동의 후 비공개 채널 사이트 파일 목록 200]({{ "/assets/images/2026/10/m22-2-private-channel-files-200.png" | relative_url }})
*그림 8. 동의 후 비공개 채널 사이트 `drive/root/children` 조회가 200 OK. D3-test-ch-private.txt(마지막 수정 2026-10-22)가 반환된다. 요청 주소와 사이트·테넌트 식별자는 가렸다.*

![동의 후 공유 채널 사이트 파일 목록 200]({{ "/assets/images/2026/10/m22-3-shared-channel-files-200.png" | relative_url }})
*그림 9. 동의 후 공유 채널 사이트 `drive/root/children` 조회가 200 OK. D3-test-ch-shared.txt(마지막 수정 2026-10-22)가 반환된다. 요청 주소와 식별자는 가렸다.*

- **결론**: 403(읽기 쪽)의 원인은 멤버십이나 사용자 권한이 아니라 **토큰의 파일·사이트 읽기 범위 부족**입니다. 범위를 추가하자 같은 계정으로 바로 읽혔습니다.
- **확인 불가**: 두 범위(Files.Read.All, Sites.Read.All)를 한 번에 동의해서 둘 중 하나만으로 충분한지는 구분하지 못했습니다(구분하려면 하나를 철회한 뒤 다시 조회해야 함). 업로드(쓰기)는 다시 시도하지 않아 쓰기 범위로 성공하는지도 확인하지 못했습니다.
- **정리**: 동의한 읽기 범위는 필요가 없어지면 Entra 관리 센터의 엔터프라이즈 애플리케이션에서 철회할 수 있습니다.
