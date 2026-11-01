---
title: "[Study] 하이브리드 ID: Entra Connect, PHS, PTA, Federation"
date: 2026-10-31 10:04:00 +0900
categories: [study]
phase: 1단계 구조와 신원
seq: 3
tags: [Study, Hybrid identity, Entra Connect, PHS, PTA, Federation]
excerpt: "어떤 로그인 방식을 고르든 PHS는 켜 두라는 것이 공식 권고입니다. PHS, PTA, Federation 중 고르는 기준"
---

온프레미스 AD는 그대로 두고 클라우드 로그인 방식만 정하려면 PHS, PTA, Federation 중 하나를 골라야 합니다. 공식 권고는 어떤 방식을 고르든 PHS를 함께 켜 두는 것이고, 이번 주에는 그 이유와 세 방식의 차이를 비교 기준으로 정리합니다.

## 요약

- hybrid identity 설계는 온프레미스 AD를 그대로 두고 클라우드 로그인을 PHS, PTA, Federation 중 무엇으로 처리할지 고르는 데서 시작
- **PHS는 항상 켜 두는 것이 공식 권고**. 온프레미스 장애 때 PHS로 수동 전환해 복구 가능
- 로그인 시점에 계정 상태를 즉시 반영해야 하면 PTA, 기존 AD FS 투자나 페더레이션 IdP가 꼭 필요한 인증 요건이 있으면 Federation 검토. 서드파티 MFA만이 목적이면 external MFA로 PHS·PTA에서도 가능
- 신규·초기화 디바이스는 **Entra join**이 공식 방향, hybrid join은 전환기의 중간 단계

12주 학습 로드맵의 3주차입니다. 이전 글: [2주차 Entra ID 기본]({{ "/study/entra-id-directory-basics/" | relative_url }}) · 다음 글: [4주차 인증 보안]({{ "/study/auth-security-mfa-ca-pim/" | relative_url }}) · 전체 계획: [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

Hybrid identity, Microsoft Entra Connect Sync, Microsoft Entra Cloud Sync, Sync cycle(Delta·Initial), sourceAnchor·ImmutableId, PHS(Password Hash Synchronization), PTA(Pass-through Authentication), PTA agent, Federation(AD FS·WAP), Seamless SSO, Staged rollout, Password writeback, SSPR, Entra hybrid join, SCP(Service Connection Point), Primary Refresh Token(PRT), Entra Connect Health

### 2. 개념 설명

Entra Connect는 두 가지를 합니다.

- **동기화(provisioning)**: 온프레미스 객체를 Entra ID로 복제합니다. 객체 동기화 주기는 기본 30분이고, 비밀번호 해시 동기화는 약 2분마다 도는 별도 프로세스입니다(이 주기는 바꿀 수 없음).
- **인증 방식 구성**: PHS, PTA, Federation 중 무엇으로 로그인할지 정합니다.

세 방식의 동작 원리, 동기화 도구(Connect Sync, Cloud Sync) 비교표, 최신 전환 일정은 [IAM 하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})에 정리했습니다. 여기서는 학습서의 비교 기준을 그대로 옮깁니다.

#### 세 가지 인증 방식 비교 (공식 문서 기준)

- **PHS**
    - 인증이 일어나는 곳: 클라우드. 동기화된 해시로 Entra ID가 검증
    - 추가 온프레미스 서버: 없음
    - 네트워크 요건: 없음
    - TLS/SSL 인증서: 불필요
    - 계정 상태 반영: 비활성화 계정만, 최대 30분 지연 (계정 상태는 정기 동기화 주기를 따름. 잠금·비밀번호 만료 상태는 동기화되지 않음)
    - 비밀번호 해시의 클라우드 저장: 있음 (해시를 한 번 더 해시한 값)
    - 온프레미스 장애 시: 클라우드 로그인 가능
- **PTA**
    - 인증이 일어나는 곳: 클라우드. 온프레미스 에이전트와 보안 검증 후
    - 추가 온프레미스 서버: 추가 에이전트마다 서버 1대 (에이전트는 1개 이상 필요, 공식 권장은 Entra Connect 서버의 첫 에이전트를 포함해 3개)
    - 네트워크 요건: 에이전트 서버의 아웃바운드 인터넷
    - TLS/SSL 인증서: 불필요
    - 계정 상태 반영: 비활성, 잠금, 만료, 비밀번호 만료, 로그인 시간 반영
    - 비밀번호 해시의 클라우드 저장: 없음
    - 온프레미스 장애 시: 에이전트와 DC 필요
- **Federation (AD FS)**
    - 인증이 일어나는 곳: 온프레미스
    - 추가 온프레미스 서버: AD FS 2대 이상, WAP 2대 이상
    - 네트워크 요건: WAP 인바운드 인터넷, 로드밸런싱
    - TLS/SSL 인증서: 필요
    - 계정 상태 반영: PTA와 동일
    - 비밀번호 해시의 클라우드 저장: 없음
    - 온프레미스 장애 시: AD FS, WAP, DC 필요

#### 선택 기준

- **PHS를 항상 켜 두라는 것이 공식 권고입니다.** 다른 방식을 쓰더라도 PHS를 함께 켜 두면 온프레미스 장애 때 PHS로 전환해 복구할 수 있습니다. 전환은 자동이 아니라 Entra Connect에서 수동으로 해야 합니다.
- Entra ID Protection의 유출 자격 증명(leaked credentials) 탐지와 Entra Domain Services는 어떤 인증 방식을 쓰든 PHS가 필요합니다.
    - 유출 자격 증명 탐지에 PHS가 필요한 대상은 동기화된(hybrid) 사용자입니다. 클라우드 전용 계정은 PHS 없이도 대조되고, PHS를 켠 뒤 새로 발견된 유출분부터 대조합니다.
    - 탐지 자체는 Free·P1에서도 생기지만, Risky users 보고서의 전체 정보와 위험 기반 정책은 P2가 필요합니다. Free·P1에서는 중·고위험 사용자만 제한적으로 보입니다.
- PTA는 로그인 시점에 온프레미스 계정 상태(비활성, 잠금, 만료, 로그인 시간)를 즉시 반영해야 하는 조직에서 고릅니다. 에이전트는 DC에 접근할 수 있어야 하므로 DMZ에 둘 수 없습니다.
- Federation은 기존 AD FS 투자가 있거나, 페더레이션 IdP를 요구하는 서드파티 MFA나 인증 솔루션, 다중 사이트 온프레미스 인증 같은 요건이 있을 때 고릅니다. 운영과 장애 분석은 셋 중 가장 복잡합니다.
    - 서드파티 MFA만이 목적이라면 Federation이 필수는 아닙니다. External MFA(이전 이름 external authentication methods)로 PHS·PTA 환경에서도 외부 MFA 공급자를 쓸 수 있습니다.
    - 스마트카드 로그인도 Microsoft Entra CBA(certificate-based authentication)로 AD FS 없이 PHS·PTA 환경에서 할 수 있습니다.
- Seamless SSO는 PHS나 PTA와 함께 쓰며, 회사 네트워크 안의 도메인 가입 PC가 Kerberos로 자동 로그인되게 합니다.

#### 디바이스 관점의 하이브리드 (hybrid join)

- Entra hybrid join은 온프레미스 AD 도메인에 가입된 기존 PC를 Entra ID에도 등록하는 방식입니다. 최초 로그인과 관리를 위해 DC까지의 네트워크 경로(line of sight)가 필요합니다.
- 공식 방향은 새 디바이스와 초기화한 디바이스는 **Entra join**을 쓰는 것입니다.
    - hybrid join은 전환기의 중간 단계이고 장기 목표가 아닙니다.
    - 기존 hybrid join 디바이스를 Entra join으로 바꾸려면 Windows를 다시 설치해야 합니다.
- 두 방식은 같은 환경에 공존할 수 있습니다.

#### 동기화 운영 포인트

- 동기화 주기를 직접 바꿨다면 최소 7일 안에는 delta sync가 한 번 돌아야 합니다. 그렇지 않으면 full sync가 필요해집니다.
- 동기화 규칙을 바꾸기 전에는 scheduler를 끕니다.
    - 범위(scope) 필터를 바꾸면 대상 디렉터리의 객체가 삭제될 수 있으니 staging 서버에서 먼저 확인합니다.
- Entra Connect Sync는 sync engine을 가진 서버형이고, Entra Cloud Sync는 경량 에이전트 기반입니다. 다중 포리스트 같은 요건에서 선택을 검토합니다.
    - Microsoft는 Connect Sync에서 Cloud Sync로의 단계적 전환을 시작했고, 2026년 7월부터 M365 메시지 센터, Entra Connect Health, 이메일로 조직별 전환 일정을 알립니다. 정리는 [IAM 하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})에 있습니다.

```powershell
# Entra Connect 서버에서 실행
Import-Module ADSync
Get-ADSyncScheduler
Start-ADSyncSyncCycle -PolicyType Delta      # 변경분 동기화
Start-ADSyncSyncCycle -PolicyType Initial    # 전체 동기화 (시간이 오래 걸릴 수 있음)
```

### 3. 온프레미스로 번역하면

PHS는 계정 정보 사본을 클라우드가 들고 직접 판단하는 방식이고, PTA는 클라우드가 묻고 온프레미스가 대신 확인하는 방식입니다. Federation은 로그인 자체를 온프레미스 IdP로 넘깁니다.

AD FS 경험이 있다면 Federation은 이미 익숙한 구조입니다.

### 4. 실습 (GUI 우선)

온프레미스 AD 랩이 없다면 화면과 문서 중심으로 진행합니다.

1. Entra 관리 센터의 Entra ID > Entra Connect > Connect sync 화면을 열어 동기화 상태(Sync status)와 마지막 동기화 시각을 확인합니다.
2. 장치(Devices) 화면에서 Join type이 Microsoft Entra joined, hybrid joined, registered 중 무엇인지 열을 확인합니다.
3. 위 PHS, PTA, Federation 비교를 본인 말로 다시 써 봅니다. 가장 중요한 실습입니다.

PTA 에이전트 장애로 로그인이 실패할 때의 대처는 [PTA 장애 글]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }})에 있습니다.

### 5. 전문가처럼 말하기

> "인증 방식은 PHS를 기본으로 켜고, 계정 상태를 로그인 시점에 즉시 반영해야 하면 PTA를 추가합니다. Federation은 AD FS 투자가 있거나 페더레이션 IdP가 꼭 필요한 인증 요건이 있을 때만 유지하고, 서드파티 MFA는 external MFA로 붙입니다."
>
> "신규 디바이스는 Entra join, 기존 domain joined 디바이스는 hybrid join으로 두고 교체 시점에 Entra join으로 옮기는 것이 공식 권고입니다."

### 6. 자가 점검

<details markdown="1">
<summary>자가 점검 문제와 답 펼쳐 보기 (5문항)</summary>

- [ ] PHS, PTA, Federation 각각에서 인증이 어디서 일어나는지 말할 수 있다.
    - 답: PHS는 클라우드(동기화된 해시로 Entra ID가 검증), PTA는 클라우드가 온프레미스 에이전트를 거쳐 확인, Federation은 온프레미스입니다.
- [ ] PHS를 다른 방식과 함께 켜 두라고 권고하는 이유 두 가지를 말할 수 있다.
    - 답: 온프레미스 장애 때 PHS로 수동 전환해 복구할 수 있고, 동기화된 사용자의 유출 자격 증명 탐지(보고서 전체 정보는 P2)와 Entra Domain Services가 PHS를 필요로 합니다.
- [ ] PTA 에이전트를 DMZ에 둘 수 없는 이유를 설명할 수 있다.
    - 답: 에이전트가 DC에 접근해 계정을 확인해야 하기 때문입니다.
- [ ] Entra join과 hybrid join 중 신규 디바이스에 무엇을 권장하는지 말할 수 있다.
    - 답: Entra join입니다. hybrid join은 전환기의 중간 단계입니다.
- [ ] 기본 동기화 주기와 수동으로 delta sync를 실행하는 명령을 말할 수 있다.
    - 답: 기본 30분이고, Entra Connect 서버에서 `Start-ADSyncSyncCycle -PolicyType Delta`를 실행합니다.

</details>

### 7. 영상 (한글 우선)

- 한글: 확인 불가. 하이브리드 ID를 다룬 한글 유튜브 영상을 검색으로 찾아봤지만 찾지 못했습니다. 대신 Microsoft Learn(한국어)에서 "Microsoft Entra 하이브리드 ID 인증 방법 선택"을 검색해 비교표를 읽으세요.
- 영문 보완
    - [Identity Architecture: Microsoft Entra Connect](https://www.youtube.com/watch?v=F0ldcCfCWNw) (동기화 구조)
    - [Entra ID Connect 설치 (hybrid join)](https://www.youtube.com/watch?v=RPj53B7rxYU)
    - [How to Configure Microsoft Entra Hybrid Join Device](https://www.youtube.com/watch?v=_vA5_OJPcTk)

### 8. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (9건)</summary>

- 문서: [Choose the right authentication method for your Microsoft Entra hybrid identity solution](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn): 비교표(비활성화 계정 최대 30분 지연, 잠금·비밀번호 만료 미동기화), PTA 에이전트 1개 이상·3개 권장, Federation이 필요한 요건, PHS·PTA에서 인증서·스마트카드 로그인 지원
- 문서: [Implement password hash synchronization with Microsoft Entra Connect Sync](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization): 비밀번호 해시 동기화는 2분마다, 주기 변경 불가
- 문서: [Microsoft Entra Connect Sync: Scheduler](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-sync-feature-scheduler): 기본 동기화 주기 30분, 7일 규칙
- 문서: [Manage an external multifactor authentication method in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/authentication/how-to-authentication-external-method-manage): External MFA(이전 이름 external authentication methods)
- 문서: [What is Microsoft Entra certificate-based authentication?](https://learn.microsoft.com/entra/identity/authentication/concept-certificate-based-authentication): AD FS 없이 Entra ID에서 직접 인증서 인증
- 문서: [Frequently asked questions around Microsoft Entra ID Protection](https://learn.microsoft.com/entra/id-protection/id-protection-faq): 유출 자격 증명 탐지는 하이브리드 사용자에게 PHS 필요, PHS 이후 발견분만 대조
- 문서: [Secure your Microsoft Entra identity infrastructure: Step 1](https://learn.microsoft.com/azure/security/fundamentals/steps-secure-identity#step-1-strengthen-your-credentials): 유출 자격 증명 보고서는 PHS를 켰거나 클라우드 전용 ID일 때 대조
- 문서: [What is Microsoft Entra ID Protection? (License requirements)](https://learn.microsoft.com/entra/id-protection/overview-identity-protection#license-requirements): Free·P1은 Risky users 제한 표시, P2 전체 접근
- 문서: [Microsoft Entra releases and announcements: April 2026](https://learn.microsoft.com/entra/fundamentals/whats-new#april-2026): Connect Sync → Cloud Sync 전환, 2026년 7월부터 조직별 알림

</details>
