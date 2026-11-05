---
title: "[Troubleshooting] 계정을 막았는데 퇴사자가 여전히 메일·파일에 접근할 때"
date: 2026-11-01 09:06:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 6
tags: [Troubleshooting, Entra ID, 퇴사자, 세션 해지, 토큰, CAE, 하이브리드, PHS]
excerpt: "퇴사자 계정을 막았는데 메일이 계속 열린다면 남은 토큰·세션 때문. 사용 안 함 → 세션 해지 → 기기 사용 안 함 순서로 끊습니다"
---

퇴사자 계정을 사용 안 함으로 바꿨는데 휴대폰 메일 앱이나 열려 있던 브라우저에서는 한동안 계속 접근됩니다. 이미 발급된 토큰·세션과 동기화 주기 때문이며, 사용 안 함 → 세션 해지 → 기기 사용 안 함 순서로 끊어야 합니다.

## 요약

- 계정 사용 안 함만으로는 남은 토큰과 앱 세션이 바로 끊기지 않음
- 퇴사 절차에 세션 해지를 넣고 하이브리드는 사내 AD부터 막아야 함
- 자체 세션을 쓰는 SaaS 앱은 그 앱 관리 화면에서 따로 끊어야 할 수 있음

> Microsoft Learn 문서(2026-11-01 확인) 기준입니다. 그림 2~6의 화면(계정 사용 안 함, 세션 취소)은 샌드박스 테넌트에서 직접 캡처했고, 나머지는 문서 기준이며 재현하지 않았습니다.

---

## 전체 내용

### 1. 증상

※ 아래 증상은 문서 내용을 바탕으로 가정한 예시이며 실제 테넌트에서 재현한 것이 아닙니다.

- 인사팀 요청으로 퇴사자 계정을 예: 오전 10시에 **사용 안 함**으로 바꿨습니다.
- 그 뒤에도 개인 휴대폰 메일 앱, 열려 있던 SaaS 앱 탭에서 한동안 접근 기록이 남습니다.

### 2. 원인 및 분석

계정을 막아도 이미 발급된 토큰과 앱 세션은 만료나 무효화 전까지 남습니다([Revoke user access in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/users/users-revoke-access)).

| 남는 것 | 문서 기준값 | 끊기는 시점 |
|---|---|---|
| **액세스 토큰** | 기본 60~90분(평균 75분) | 만료 뒤 새로 받으려 할 때 막힘 |
| CAE 지원 앱·클라이언트 | 더 긴 토큰, CAE 세션 최대 28시간 | 계정 사용 안 함·삭제, 암호 변경, 세션 해지, 높은 사용자 위험 시 무효화(목표는 몇 분, 최대 15분 지연 가능). Exchange Online, SharePoint Online, Teams 등 |
| 조건부 액세스 없는 테넌트의 Teams·M365 클라이언트 | 기본 2시간 | 만료 시 |
| 앱 자체 세션 쿠키 | 앱이 발급, Entra ID가 직접 끊을 수 없음 | 앱이 다시 Entra로 보낼 때 |
| 하이브리드 동기화 | Entra Connect Sync 기본 30분 주기 | 사내 AD 차단이 클라우드에 반영될 때 |

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-disabled-user-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-disabled-user.png" | relative_url }}" alt="계정을 막은 뒤에도 로그인이 남는 이유 4가지와 즉시 끊는 4단계" loading="lazy"></picture>

*그림 1. 남는 이유와 즉시 끊는 순서. 표의 액세스 토큰 계열(1~3행)을 그림에서는 '액세스 토큰'과 'CAE'로 묶어 4가지로 정리했습니다.*

### 3. 결론

`사용 안 함만 실행 → 남은 토큰·앱 세션(·동기화 대기) → 개인 휴대폰 메일, 열린 탭에서 접근 지속`

앞의 세 단계(사용 안 함, 세션 해지, 기기 사용 안 함)를 한 번에 실행해야 끊기고, 4번 인증 방법 정리는 재입사·계정 재사용 사고를 막는 후속 정리입니다.

### 4. 권고방안

1. 조치(GUI, Entra 관리 센터):
    1. **사용 안 함**: Entra ID > Users > All users > 해당 사용자 > Account status 옆 Edit(편집) > Properties(속성 편집)의 설정 탭에서 Account enabled(화면 표기 '사용하는 계정') 해제 > Save(저장). 클라우드 전용 사용자 기준이며, 동기화된 하이브리드 사용자는 이 단계를 사내 AD에서 합니다
    2. **세션 해지**: 사용자 개요 위쪽 Revoke sessions(화면 표기 '세션 취소', 이 글의 '세션 해지'와 같음). 모든 리프레시 토큰이 무효화되어 다시 로그인해야 함
    3. **기기 사용 안 함**: Entra ID > Devices > All devices에서 해당 사용자의 기기를 **Disable**(문서는 PowerShell로 안내하므로 아래 스크립트도 제시)
    4. **인증 방법 정리**: 사용자 > Authentication methods에서 등록된 방법 제거(재입사·계정 재사용 사고 방지)
    5. 필요하면 라이선스 회수, 메일 전달·사서함 보존은 회사 규정대로
2. 하이브리드: 사내 AD에서 먼저 **사용 안 함** + 암호 두 번 재설정(pass-the-hash 위험 완화, 침해되지 않았다고 확신하면 한 번도 가능) 후, 동기화를 기다리지 말고 Entra에서는 2~4번(세션 해지, 기기 사용 안 함, 인증 방법 정리)을 실행하고(문서 기준이며, 동기화 사용자의 계정 사용 여부는 AD 기준이라 Entra에서 직접 바꾸기 어렵다는 점이 문서에 있습니다. 2~4번이 동기화 사용자에게 실제로 적용되는지는 이 글에서 시험하지 않았습니다) 필요하면 델타 동기화를 돌립니다.
3. 조치 후 확인: 로그인 로그에서 새 로그인 시도가 **50057(UserDisabled)** 등으로 실패하고, 사용자 속성의 SignInSessionsValidFromDateTime이 세션 해지 시각으로 바뀌면 됩니다.
4. 절차화: 퇴사 체크리스트에 **세션 해지**를 넣고, ID Governance가 있으면 Lifecycle Workflows로 자동화합니다.
5. 자체 세션을 쓰는 SaaS 앱은 그 앱의 관리 화면에서 세션을 따로 끊습니다.

<details markdown="1">
<summary>샌드박스에서 직접 한 화면 보기 (그림 5장)</summary>

![사용자 개요 화면. 계정 상태가 사용이고 위쪽에 속성 편집, 세션 취소 버튼이 있음]({{ "/assets/images/2026/11/ts-disabled-user-1-before.png" | relative_url }})

*그림 2. 시험 사용자 개요(Entra ID > 사용자 > 사용자 선택). 계정 상태가 "사용"이고, 위쪽 도구 모음에 속성 편집과 세션 취소가 있습니다. 이름, 계정, 개체 ID는 가렸습니다.*

![속성 편집의 설정 탭에서 사용하는 계정 체크박스를 해제한 화면]({{ "/assets/images/2026/11/ts-disabled-user-2-uncheck.png" | relative_url }})

*그림 3. 속성 편집 > 설정 탭. "사용하는 계정" 체크를 해제하고 저장합니다. 체크를 다시 켜면 되돌아갑니다.*

![저장 뒤 사용자 개요. 계정 상태가 사용 안 함으로 바뀜]({{ "/assets/images/2026/11/ts-disabled-user-3-after.png" | relative_url }})

*그림 4. 저장 뒤 개요 화면. 계정 상태가 "사용 안 함"으로 바뀌었습니다.*

![세션 취소 확인 메시지. 사용자는 모든 디바이스에서 다시 로그인해야 한다는 안내]({{ "/assets/images/2026/11/ts-disabled-user-4-revoke.png" | relative_url }})

*그림 5. 세션 취소를 누르면 나오는 확인. 사용자는 모든 디바이스에서 다시 로그인해야 한다고 안내합니다.*

![로그인 세션을 취소했다는 완료 알림]({{ "/assets/images/2026/11/ts-disabled-user-5-toast.png" | relative_url }})

*그림 6. "로그인 세션을 취소했습니다." 알림. 시험이 끝난 뒤 계정 사용을 다시 켜 원래대로 돌려놓았습니다(복구 화면은 캡처하지 않았습니다).*

</details>

<details markdown="1">
<summary>PowerShell 스크립트 전체 보기 (Graph, 사내 AD, 델타 동기화)</summary>

여러 명을 GUI로 처리하기 어려우면 문서의 Microsoft Graph PowerShell 순서를 씁니다. 한 명 기준입니다.

```powershell
# 필요한 모듈: Microsoft.Graph (Users, Users.Actions, Identity.DirectoryManagement)
# 필요 역할: 사용자 관리자 이상(관리자 계정이면 권한 있는 인증 관리자), 기기는 클라우드 디바이스 관리자
# Device.ReadWrite.All은 위임 권한이 없어 대화형 로그인에 쓰지 않음
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.AccessAsUser.All"

$upn  = "leaver@contoso.com"   # 퇴사자 UPN
$User = Get-MgUser -Filter "userPrincipalName eq '$upn'"

# 클라우드 전용 사용자만. 동기화 사용자는 AD에서 사용 안 함
# 1) 계정 사용 안 함
Update-MgUser -UserId $User.Id -AccountEnabled:$false

# 2) 리프레시 토큰·세션 해지
Revoke-MgUserSignInSession -UserId $User.Id

# 3) 등록된 기기 사용 안 함
Get-MgUserRegisteredDevice -UserId $User.Id -All | ForEach-Object {
    Update-MgDevice -DeviceId $_.Id -AccountEnabled:$false
}

# 확인
Get-MgUser -UserId $User.Id -Property AccountEnabled,SignInSessionsValidFromDateTime |
    Select-Object AccountEnabled, SignInSessionsValidFromDateTime
```

```powershell
# (하이브리드) 사내 AD — 도메인 관리 권한이 있는 PC에서 (ActiveDirectory 모듈)
$sam = "leaver"   # 퇴사자 sAMAccountName
Disable-ADAccount -Identity $sam
# 암호 두 번 재설정 (예시 문자열 대신 매번 무작위 값 사용)
1..2 | ForEach-Object {
    $pw = -join ((33..126) | Get-Random -Count 24 | ForEach-Object {[char]$_})
    Set-ADAccountPassword -Identity $sam -Reset -NewPassword (ConvertTo-SecureString $pw -AsPlainText -Force)
}
```

```powershell
# (하이브리드) Entra Connect Sync 서버에서 상태를 맞추는 델타 동기화
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
```

스크립트는 문서의 명령을 한 사람 처리용으로 묶은 것입니다. 실행 결과(성공 여부)는 이 글에서 재현하지 않았습니다. 운영에 쓰기 전에 시험 계정으로 먼저 확인하세요.

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- 하이브리드 차단 순서(AD 사용 안 함 → 암호 두 번 재설정 → Entra 차단), 앱 세션 토큰, 하이브리드 사용자 차단 순서(PowerShell): [Revoke user access in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/users/users-revoke-access)
- 액세스 토큰 기본 수명 60~90분: [Access tokens in the Microsoft identity platform](https://learn.microsoft.com/entra/identity-platform/access-tokens)
- CAE 중요 이벤트, 지원 서비스와 클라이언트: [Continuous access evaluation](https://learn.microsoft.com/entra/identity/conditional-access/concept-continuous-access-evaluation)
- Entra Connect Sync 기본 30분, 수동 델타 동기화: [Microsoft Entra Connect Sync: Scheduler](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-sync-feature-scheduler)
- 50057 UserDisabled: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)

</details>
