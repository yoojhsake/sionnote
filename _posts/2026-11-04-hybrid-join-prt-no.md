---
title: "[Troubleshooting] 하이브리드 조인 후 AzureAdPrt가 NO로 나올 때"
date: 2026-11-04 16:00:00 +0900
categories: [iam, troubleshooting]
area: 하이브리드 동기화·에이전트
seq: 3
tags: [Troubleshooting, 하이브리드 조인, PRT, AADSTS50057, AADSTS90002, dsregcmd, 장치 동기화, 사용자 동기화]
excerpt: "조인은 성공했는데 사용자 로그인 뒤에도 AzureAdPrt가 NO였음. 관리자 계정은 UPN 접미사 .local 때문에 토큰 요청이 AADSTS90002로 거부됐고, 테스트 계정은 AD에서 막 켠 직후 Entra에서 비활성이어서(AADSTS50057) 생긴 결과였다"
toc: true
last_modified_at: 2026-11-05 00:55
---

하이브리드 조인이 끝난 PC에서 로그인한 뒤 `dsregcmd /status`의 AzureAdPrt가 NO로 나왔습니다. 도메인 관리자 계정은 동기화 범위 밖이라 Entra에 계정이 없었고(조회, 사용자 검색 0명) UPN 접미사도 `.local`이었는데, 이벤트 로그에서 토큰 요청이 AADSTS90002(Tenant 'sionnote.local' not found)로 거부된 것을 확인해 직접 원인은 접미사로 가려졌습니다(조회). 테스트 계정은 AD에서 켠 직후 Entra에서는 계정이 아직 비활성이어서(AADSTS50057) NO였고, 범위 안 계정이 Entra에서 활성화된 뒤 다시 로그인하자 YES가 됐습니다.

## 요약

- PRT는 조인 뒤 사용자가 로그인할 때 받으며, 조인 직후 NO는 정상일 수 있음
- 로그인 사용자가 Entra에서 비활성이면(조회, AADSTS50057) PRT가 안 나옴. Entra에 사용자가 없을 때도 안 나오고 AADSTS50034가 난다고 문서가 안내함(문서, 이 랩에서는 관측하지 못함). 오류 코드는 SSO State나 AAD Operational 이벤트 로그에 남음
- AD에서 계정을 켠 뒤에는 Entra가 반영될 때까지 기다리거나 요청 시 프로비전으로 앞당겨야 함
- 계정이 Entra에 있고 활성이어도 AD의 UPN 접미사가 Entra에 없는 도메인(.local)이면 PRT가 NO(AADSTS90002)이고, UPN을 바꾼 뒤에는 로그오프 후 새로 로그인해야 반영됨

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못하고 관찰값에서 이어 붙인 해석. 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)과 이벤트의 요청 추적용 ID(Trace·Correlation ID)는 가렸고(빈칸으로 보임), 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 증상

- 조인한 PC에서 AzureAdJoined와 DomainJoined가 YES, DeviceAuthStatus가 SUCCESS인데 AzureAdPrt는 NO(조회)
- 도메인 관리자 계정(UPN이 .local, OU=Admins)으로 로그인했을 때 NO(조회)
- 테스트 계정(OU=CloudSync)으로 로그인했을 때 NO였고, SSO State에 오류가 표시됨(조회)
- 같은 테스트 계정에서 AD의 UPN 접미사를 .local로만 바꾸면 PRT가 NO(AADSTS90002), 테넌트 도메인으로 되돌리고 새로 로그인하면 YES(조회)

### 2. 원인 및 분석

PRT는 조인된 장치에서 사용자가 로그인할 때 Entra가 발급하는 토큰입니다(문서). 기대값은 로그인한 사용자가 Entra에도 활성 계정으로 있고 그 계정으로 토큰을 받는 것입니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 사례 1: 동기화 범위 밖 관리자 계정

도메인 관리자 계정은 OU=Admins 아래에 있고 UPN이 .local 접미사였습니다. 이 OU는 Connect Sync(ConnectSync OU)와 Cloud Sync(CloudSync OU) 어느 쪽 범위에도 없습니다(조회). 그래서 Entra에 대응하는 사용자가 없을 것으로 봤고, 포털에서 확인했습니다. Entra 관리 센터 → 사용자 → 모든 사용자에서 `yadmin`으로 검색하면 결과가 0명입니다(조회, 2026-11-04 15:45경, 이름·계정 이름 앞부분 검색 기준). 이 계정으로 로그인한 PC(cl11)에서 `dsregcmd`의 SSO State와 Diagnostic Data를 읽으면 AzureAdPrt는 NO이고 Executing Account Name은 `SIONNOTE\yadmin, yadmin@sionnote.local`입니다(조회, 2026-11-04 저녁). Cloud Test02 계정의 SSO State(아래 사례 2)와 달리 Attempt Status·Server Error 같은 실패 기록 줄이 없습니다(조회). 이 계정이 PRT를 못 받은 원인 후보는 둘이었습니다. 하나는 Entra에 사용자가 없는 것, 다른 하나는 UPN 접미사 `.local`을 도메인으로 가진 테넌트가 없는 것입니다. 이 구분은 하이브리드 조인 상태로 남아 있는 cl10에서 yadmin으로 다시 로그인해 Microsoft Entra Operational 로그(이벤트 뷰어 → 응용 프로그램 및 서비스 로그 → Microsoft → Windows → AAD → Operational)를 읽어 풀었습니다(조회, 2026-11-05 00:01:44).

[![cl10 AAD Operational 로그: yadmin 로그온 시각 00:01:44에 오류 4건(이벤트 1160, 1085, 1081, 1025)(GUI)]({{ "/assets/images/2026/11/aad-op-cl10-yadmin-list.png" | relative_url }})]({{ "/assets/images/2026/11/aad-op-cl10-yadmin-list.png" | relative_url }}){:target="_blank"}

이벤트 1081에는 OAuth 응답 오류 invalid_request와 설명 "AADSTS90002: Tenant 'sionnote.local' not found"가 기록돼 있습니다(조회). 이벤트 1025는 같은 시각 토큰 엔드포인트 요청이 HTTP 400으로 끝났다는 기록이고(조회, 엔드포인트 주소에 테넌트 ID가 들어 있어 캡처는 싣지 않음), 이벤트 1085와 1160은 Logon failure 상태 0xC00000D0입니다(조회).

[![이벤트 1081: invalid_request, AADSTS90002 Tenant 'sionnote.local' not found(GUI)]({{ "/assets/images/2026/11/aad-op-cl10-yadmin-event1081.png" | relative_url }})]({{ "/assets/images/2026/11/aad-op-cl10-yadmin-event1081.png" | relative_url }}){:target="_blank"}

[![이벤트 1085: Logon failure, 상태 0xC00000D0(GUI)]({{ "/assets/images/2026/11/aad-op-cl10-yadmin-event1085.png" | relative_url }})]({{ "/assets/images/2026/11/aad-op-cl10-yadmin-event1085.png" | relative_url }}){:target="_blank"}

정리하면 cl10에서 yadmin으로 다시 로그온한 1건(2026-11-05 00:01)에서 서버는 UPN의 도메인 `sionnote.local`에 해당하는 테넌트를 찾지 못한다고 응답했습니다(AADSTS90002, 조회). 공식 문서는 이 오류를 이메일 주소(UPN)에서 유추한 테넌트의 도메인이 등록되어 있지 않을 때도 나는 오류로 설명합니다(문서: Microsoft Entra authentication and authorization error codes). 아래 대조 테스트의 Cloud Test02(.local 접미사일 때 AADSTS90002)와 같은 오류 코드입니다. 이 로그온에서 PRT를 막은 직접 원인은 `.local` 접미사이며, 사용자 조회 단계가 시도되지 않았거나 기록되지 않았습니다. Entra에 사용자가 없다는 사실(검색 0명)은 별개로 확인한 것입니다. 이벤트 캡처의 사용자 칸은 모두 SYSTEM이라 그것만으로는 yadmin의 이벤트인지 알 수 없습니다. 그래서 같은 PC의 보안 로그에서 yadmin의 로그온 기록(4624)을 함께 조회했고, 2026-11-05 00:01:44에 yadmin 로그온(logonType=10, 원격 대화형)과 AAD 1081(AADSTS90002)이 같은 초에 있었습니다(조회). 확정 범위는 이 로그온 1건입니다.

```powershell
# 관리자 권한 PowerShell (보안 로그 조회에 필요)
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624;StartTime='2026-11-05 00:00:00';EndTime='2026-11-05 00:03:00'} |
  Where-Object { $_.Properties[5].Value -eq 'yadmin' } | Sort-Object TimeCreated |
  ForEach-Object { '{0:HH:mm:ss}  Security 4624  yadmin  logonType={1}' -f $_.TimeCreated,$_.Properties[8].Value }
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-AAD/Operational';Id=1081;StartTime='2026-11-05 00:00:00';EndTime='2026-11-05 00:03:00'} |
  Sort-Object TimeCreated | ForEach-Object { '{0:HH:mm:ss}  AAD 1081  AADSTS90002' -f $_.TimeCreated }
```

[![같은 초(00:01:44)의 yadmin 로그온 4624와 AAD 1081 AADSTS90002(PowerShell, cl10)]({{ "/assets/images/2026/11/prt-no-cl10-yadmin-4624-aad1081.png" | relative_url }})]({{ "/assets/images/2026/11/prt-no-cl10-yadmin-4624-aad1081.png" | relative_url }}){:target="_blank"}

4624가 두 줄인 것은 같은 로그온이 제한 없는 토큰과 제한된 토큰으로 한 번씩 기록되기 때문입니다(추정, 두 줄의 시각과 로그온 유형이 같음). 같은 PC에서 yadmin으로 다시 로그온한 2026-11-05 00:40~00:41에도 같은 AADSTS90002가 두 번 남았고(조회, 로그온 유형 11·7·10의 4624와 같은 시각), 이 세션에서 `whoami /upn`은 `yadmin@sionnote.local`, `dsregcmd /status`는 `AzureAdPrt : NO`, `Executing Account Name`은 `SIONNOTE\yadmin, yadmin@sionnote.local`이었습니다(조회, 00:44:39). 접미사를 고쳐도 사용자가 없어 다시 막힐 것이라는 점은 추정입니다(yadmin의 UPN은 바꿔 보지 않았습니다). cl11의 yadmin 세션은 SSO State만 읽었고(실패 기록 줄 없음, 아래 캡처), 이 글에서 직접 원인을 확정한 것은 cl10 로그온 1건입니다.

[![cl11에서 yadmin 계정으로 읽은 SSO State: AzureAdPrt NO, 실패 기록 줄 없음(PowerShell, 글꼴 확대)]({{ "/assets/images/2026/11/prt-no-cl11-yadmin-sso-state.png" | relative_url }})]({{ "/assets/images/2026/11/prt-no-cl11-yadmin-sso-state.png" | relative_url }}){:target="_blank"}

[![Entra 사용자 검색 yadmin: 0명의 사용자를 찾았음(GUI)]({{ "/assets/images/2026/11/en-users-gui-01-yadmin-search-none.png" | relative_url }})]({{ "/assets/images/2026/11/en-users-gui-01-yadmin-search-none.png" | relative_url }}){:target="_blank"}


관리자 계정(`yadmin`)으로 로그인한 두 PC의 `dsregcmd` 결과입니다(2026-11-04, 글꼴 확대). 장치는 하이브리드 조인이 정상(AzureAdJoined·DomainJoined YES, DeviceAuthStatus SUCCESS)인데 `AzureAdPrt`만 NO입니다.

[![cl10(관리자 계정): AzureAdPrt NO]({{ "/assets/images/2026/11/hj-cl10-dsreg-hybrid-hires.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-dsreg-hybrid-hires.png" | relative_url }}){:target="_blank"}

[![cl11(관리자 계정): AzureAdPrt NO]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid-hires.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid-hires.png" | relative_url }}){:target="_blank"}

이 계정이 동기화 범위 밖이라는 근거는 두 곳의 범위 설정 화면입니다. Connect Sync는 설치 마법사의 Domain/OU Filtering에서 `ConnectSync`만 선택했고, Cloud Sync는 포털의 범위 필터가 `OU=CloudSync`입니다. `OU=Admins`는 어느 쪽에도 없습니다.

[![Connect Sync의 Domain and OU filtering: ConnectSync만 선택]({{ "/assets/images/2026/11/cs-06-ou-filter.png" | relative_url }})]({{ "/assets/images/2026/11/cs-06-ou-filter.png" | relative_url }}){:target="_blank"}

[![Cloud Sync 포털의 범위 필터: OU=CloudSync만 선택]({{ "/assets/images/2026/11/cs-portal-02-scope.png" | relative_url }})]({{ "/assets/images/2026/11/cs-portal-02-scope.png" | relative_url }}){:target="_blank"}

#### 사례 2: 테스트 계정

처음에는 테스트 계정이 AD에서 비활성이었습니다(조회). 비밀번호 없이 만들어 둔 계정이라 로컬 로그인이 막혔고, 암호를 재설정하고 활성화하자 로그인은 됐습니다. 그러나 PRT는 NO였고 SSO State가 다음 오류를 보여 줬습니다(조회).

```text
Attempt Status          : 0xc0000072
Server Error Code       : invalid_grant
Server Error Description: AADSTS50057: The user account is disabled.
```

AADSTS50057은 Entra가 이 사용자를 비활성으로 본다는 뜻이므로(조회), 동기화가 AD의 활성화 변경을 아직 반영하지 않은 상태였던 것으로 봅니다(추정: Entra 포털에서 사용자의 활성 상태를 따로 캡처하지 않았습니다). 이 시도는 같은 오류로 두 번 확인됐습니다(5분 간격, 조회).

#### 앞당겨서 해결

- 포털의 Cloud sync 구성에서 **요청 시 프로비전 → 사용자 탭**에 계정의 고유 이름(DN)을 넣고 프로비전했습니다. 화면에는 오류 문구가 떴지만 사용자는 반영됐습니다(조회).
- **프로비전 다시 시작**으로 전체를 다시 돌렸습니다.
- 두 PC에서 로그아웃 후 다시 로그인하자 AzureAdPrt가 YES가 됐고, 한 PC에서는 갱신 시각도 함께 표시됐습니다(조회). 이 두 결과(SSO State 오류 출력, PRT YES)는 당시 화면을 캡처하지 않고 `dsregcmd` 출력을 옮겨 적은 것입니다. 같은 오류 화면을 다시 만들려면 계정을 다시 비활성 상태로 되돌려야 해서 재현하지 않았습니다.

**사용한 명령** — 각 PC의 PowerShell에서 PRT 항목과 실패 원인을 읽었습니다.

```powershell
dsregcmd /status | Select-String 'AzureAdPrt |AzureAdPrtUpdateTime|AzureAdPrtExpiryTime|AzureAdPrtAuthority'
dsregcmd /status | Select-String -Pattern 'SSO State' -Context 0,22   # 실패 원인까지 출력
```

#### UPN 접미사만 바꿔 본 대조 테스트

앞의 해결에서는 테스트 계정(Cloud Test02)의 AD UPN을 테넌트 도메인으로 바꾸는 것과 동기화 반영이 같은 시점에 이뤄져서, 어느 쪽이 PRT를 풀었는지 구분하지 못했습니다(변경 전 UPN 값은 기록하지 않았습니다). 그래서 다른 조건은 그대로 두고 AD의 UPN 접미사만 바꿔 sionnote-cl11에서 다시 로그인해 비교했습니다(조회, 2026-11-04 22:45~22:57). Entra의 사용자는 그대로 `<테넌트>.onmicrosoft.com` UPN으로 동기화되어 있었습니다(조회, 같은 계정으로 한 Entra 조인의 조직 확인 창에 이 UPN이 표시됨. [Entra 조인 글]({{ "/iam/entra-join-cl10-cl11/" | relative_url }}) 참고).

| 순서 | AD의 UPN 접미사 | 시각(KST) | AzureAdPrt | SSO State 오류 |
|---|---|---|---|---|
| 1 | `@sionnote.local` | 22:45 로그온 | NO | 0xc00000d0, invalid_request, AADSTS90002 (Tenant 'sionnote.local' not found) |
| (복원) | 테넌트 도메인(`.onmicrosoft.com`)으로 AD UPN 복원 | 22:49 복원, 22:54 같은 세션 재조회 | 같은 세션이라 NO 그대로(whoami /upn은 여전히 `.local`) | 1번과 동일 |
| 2 | 복원된 UPN | 22:57 로그오프 후 새 로그온 | YES | 없음 |

1번에서는 Windows 로그인이 보낸 PRT 요청의 User Identity가 `cloudtest02@sionnote.local`이었고, 이 접미사를 도메인으로 가진 테넌트가 없어 요청이 거부됐습니다. 계정은 Entra에 있고 활성인데도 PRT가 NO가 된 경우입니다.

[![UPN이 .local일 때 SSO State: AzureAdPrt NO, AADSTS90002(dsregcmd 출력)]({{ "/assets/images/2026/11/prt-upn-local-cl11-sso-state.png" | relative_url }})]({{ "/assets/images/2026/11/prt-upn-local-cl11-sso-state.png" | relative_url }}){:target="_blank"}

2번은 UPN을 되돌린 뒤 로그오프하고 새로 로그인한 결과입니다. 이 세션에서 `whoami /upn`은 복원된 UPN이고, PRT의 UpdateTime은 2026-11-04 13:49:40 UTC(22:49:40 KST), ExpiryTime은 2026-11-18 13:57:20 UTC로 표시됩니다(조회). ExpiryTime의 시각(22:57:20 KST)은 새 로그온 시각과 맞고, 갱신 때 만료가 14일 뒤로 새로 잡힌 것으로 보입니다(추정. 만료 시각은 정상 발급의 근거로 쓰지 않는다는 [Entra 조인 글]({{ "/iam/entra-join-cl10-cl11/" | relative_url }})의 기준에 따라, 이 해석은 근거가 아닌 참고로만 둡니다). UpdateTime이 로그온(22:57)보다 이른 22:49:40인 이유는 확인 불가입니다. 방법은 dsregcmd 출력과 로그온 시각의 대조였고, 사유는 PRT 갱신을 기록하는 Microsoft Entra Operational 이벤트를 이 시점에 조회하지 않았기 때문입니다.

[![UPN 복원 후 로그인: AzureAdPrt YES, CloudTgt YES, OnPremTgt NO]({{ "/assets/images/2026/11/prt-upn-restored-cl11-yes.png" | relative_url }})]({{ "/assets/images/2026/11/prt-upn-restored-cl11-yes.png" | relative_url }}){:target="_blank"}

**사용한 명령** — AD의 UPN과 로그온 세션 토큰의 UPN을 따로 읽어 비교했습니다.

```powershell
whoami /upn                                                           # 로그온 세션의 UPN
([adsisearcher]'(samaccountname=cloudtest02)').FindOne().Properties.userprincipalname   # AD에 저장된 UPN
dsregcmd /status | Select-String 'AzureAdPrt |AzureAdPrtUpdateTime|AzureAdPrtExpiryTime|CloudTgt|OnPremTgt'
```

**주의: UPN을 바꾼 뒤에는 로그오프가 필요합니다.** 복원 직후 22:54에 같은 세션에서 읽었을 때는 AD가 이미 복원된 UPN을 갖고 있었는데도 `whoami /upn`은 `@sionnote.local`이었고 PRT 시도 기록도 22:45 것 그대로였습니다(조회). 로그온 세션의 UPN은 로그온 시점에 정해지므로, 바꾼 값은 로그오프 후 새 로그인에서 반영됩니다.

</details>

### 3. 결론

로그인 사용자의 UPN 접미사가 Entra에 없거나(관리자 계정, 조회) 계정이 Entra에서 사용 가능하지 않아서(테스트 계정, 조회) PRT를 받지 못함 → AzureAdPrt NO → 원인이 풀린 뒤 재로그인에서 YES.

- 관리자 계정: UPN 접미사 `.local` → 토큰 요청이 AADSTS90002(Tenant 'sionnote.local' not found)로 거부 → PRT NO(조회, cl10 AAD Operational 이벤트 1081, 2026-11-05 00:01 로그온 1건 기준). Entra에서 사용자 검색 0명이라는 점은 별개로 확인했지만(조회) 이번 로그온을 막은 것은 접미사입니다.
- 테스트 계정: 토큰 요청이 AADSTS50057(Entra가 사용자를 비활성으로 봄)로 거부 → PRT NO(조회). 비활성이던 이유가 동기화 지연이라는 점은 추정입니다.

테스트 계정에서 UPN 접미사 하나만 바꿔 PRT가 NO(AADSTS90002)와 YES로 갈리는 것을 확인했습니다(조회). AD의 UPN 접미사가 Entra에 등록된 도메인이 아니면 Entra 계정이 정상이어도 PRT를 받지 못합니다. 공식 문서도 UPN 도메인이 Entra의 사용자 지정 도메인으로 등록되어 있어야 하고, `.local`처럼 라우팅할 수 없는 도메인은 대체 로그인 ID(AltID)가 필요하다고 설명합니다(문서). 관리자 계정은 `yadmin` 검색 결과가 0명이라 접미사를 고쳐도 사용자가 없어 다시 막힐 것으로 추정합니다(접미사를 바꿔 보지는 않음).

### 4. 권고방안

1. AD 사용자의 UPN 접미사가 Entra에 등록된 도메인인지 먼저 봅니다. `whoami /upn` 또는 AD의 userPrincipalName 접미사를 Entra 관리 센터의 도메인 이름 목록과 대조합니다(조회: 이 랩의 접미사 대조 테스트, 문서: UPN 도메인은 Entra의 사용자 지정 도메인이어야 하고 `.local`은 대체 로그인 ID가 필요). 접미사가 다르면 UPN을 바꾸고 로그오프 후 새로 로그인해야 반영됩니다.
2. `dsregcmd /status`에서 SSO State의 Server Error Description을 읽습니다. 오류 코드가 계정 비활성(AADSTS50057)인지 접미사 문제(AADSTS90002)인지 다른 원인인지 가리는 단서가 됩니다.
3. AD에서 계정을 켠 뒤에는 Cloud Sync는 요청 시 프로비전, Connect Sync는 Delta 동기화로 앞당긴 다음 재로그인합니다(조회: 두 방법 모두 이 랩에서 사용, 관련 글 참고). 다시 로그인하기 전에 포털에서 사용자의 활성 상태를 보면 시간을 아낄 수 있습니다.
4. 조인 직후의 NO를 오류로 단정하지 마세요. PRT는 로그인 사용자가 있어야 생기므로, 사용자 로그인 뒤에 확인합니다.

관련 글: [Cloud Sync로 하이브리드 조인 구성하기]({{ "/iam/hybrid-join-cloud-sync/" | relative_url }}) · [AD 조인·하이브리드 조인·Entra 조인 비교 실측]({{ "/iam/join-types-comparison/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (9건)</summary>

- **문서**: 장치 진단 항목과 SSO State 확인
    - 출처: [Troubleshoot devices by using the dsregcmd command](https://learn.microsoft.com/entra/identity/devices/troubleshoot-device-dsregcmd)
- **조회**: SSO State 오류(0xc0000072, invalid_grant, AADSTS50057)
    - 출처: sionnote-cl11 (dsregcmd /status)
- **조회**: AD 계정 비활성 상태와 OU 위치(캡처는 싣지 않고 작업 기록으로만 확인)
    - 출처: sionnote-ad01 (ADUC, Get-ADUser)
- **조회**: 요청 시 프로비전과 프로비전 다시 시작 뒤 PRT YES와 갱신 시각
    - 출처: sionnote-cl10, sionnote-cl11 (2026-11-04)
- **조회**: UPN 접미사 대조 테스트(.local → NO, AADSTS90002 / 복원 → YES), whoami /upn, AD UPN 직접 조회
    - 출처: sionnote-cl11 (dsregcmd /status, whoami /upn, adsisearcher, 2026-11-04 22:45~22:57)
- **조회**: yadmin 로그온(2026-11-05 00:01:44)의 AAD Operational 이벤트 1025(HTTP 400), 1081(AADSTS90002), 1085·1160(0xC00000D0)
    - 출처: sionnote-cl10 (이벤트 뷰어 → Microsoft → Windows → AAD → Operational)
- **조회**: yadmin 로그온 보안 로그 4624(2026-11-05 00:01:44, logonType=10)와 AAD 1081의 같은 초 일치, 재로그온(00:40~00:41)의 동일 오류, 같은 세션의 whoami /upn·dsregcmd(AzureAdPrt NO)
    - 출처: sionnote-cl10 (Get-WinEvent, whoami /upn, dsregcmd /status)
- **조회**: Entra 사용자 검색 `yadmin` 결과 0명
    - 출처: Entra 관리 센터 → 사용자 → 모든 사용자 (2026-11-04)
- **문서**: UPN 도메인은 Entra에 사용자 지정 도메인으로 있어야 하고, `.local`처럼 라우팅할 수 없는 도메인은 AltID 구성이 필요함
    - 출처: [Troubleshoot primary refresh token issues on Windows devices](https://learn.microsoft.com/entra/identity/devices/troubleshoot-primary-refresh-token), [Troubleshoot Microsoft Entra hybrid joined devices](https://learn.microsoft.com/entra/identity/devices/troubleshoot-hybrid-join-windows-current)

</details>
