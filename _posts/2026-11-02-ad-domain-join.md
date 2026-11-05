---
title: "[IAM] 서버와 클라이언트를 AD 도메인에 가입시키기"
date: 2026-11-02 22:55:00 +0900
last_modified_at: 2026-11-04 22:00:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 3
tags: [IAM, 도메인 가입, DNS, 컴퓨터 계정, OU, nltest]
excerpt: "DNS를 DC로 맞추고 컴퓨터 이름·도메인 변경 창에서 가입한다. 서버는 기본 Computers 컨테이너에, 클라이언트는 동기화 방식별 OU에 계정이 놓였다"
toc: true
---

동기화 서버(sync01)와 Windows 10·11 클라이언트(cl10, cl11)를 `sionnote.local`에 가입시켰습니다. 가입 전에 맞춰야 하는 것은 하나, **DNS를 도메인 컨트롤러로 향하게 하는 것**입니다. 이 글은 sync01의 가입 과정(캡처)과 클라이언트 두 대의 2026-11-04 11:30 시점 가입 상태를 정리합니다(이후 Entra 조인 재현으로 두 PC는 도메인을 떠났고, 내용은 [Entra 조인 글]({{ "/iam/entra-join-cl10-cl11/" | relative_url }}) 7절에 있습니다).

## 요약

- 가입 전 NIC의 DNS를 DC(`DC_IP`)로 지정해야 하고, 게이트웨이는 비워도 됨(내부 스위치)
- sync01은 컴퓨터 이름을 바꾸면서 가입했고, 계정은 기본 `Computers` 컨테이너에 생김
- cl10·cl11은 동기화 방식별 OU(`ConnectSync`, `CloudSync`)에 계정이 놓여 있고, 2026-11-04 오전 조회 시점에 cl11은 보안 채널이 정상(NERR_Success)이었고, cl10은 가입 상태(PartOfDomain True)만 조회함(nltest 미실행)

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

세 대의 컴퓨터를 도메인에 가입시켜 다음 글부터의 설정(동기화, 하이브리드 조인)이 도메인 구성원을 전제로 진행되게 합니다.

### 2. 개념

| 구분 | 서버(sync01) | 클라이언트(cl10, cl11) |
|---|---|---|
| 운영체제(조회) | Windows Server 2022 Standard Evaluation | cl11: Windows 11 Enterprise 10.0.22631 · cl10: Windows 10 Enterprise 10.0.19045(Entra 장치 목록 버전 열의 10.0.19045.5073에서 읽음) |
| 가입 위치 | 서버 관리자 → 로컬 서버 → 컴퓨터 이름·도메인 변경 | 같은 창 또는 설정 → 계정 → 회사 또는 학교 액세스(문서) |
| 컴퓨터 계정 위치(조회) | 기본 컨테이너 `CN=Computers` | `OU=CloudSyncLab` 아래 `ConnectSync`(cl10), `CloudSync`(cl11) |
| 가입 뒤 할 일 | 동기화 에이전트 설치 | 하이브리드 조인·Entra 조인 시험 |

컴퓨터 계정이 어느 OU에 있느냐는 뒤 글에서 중요합니다. 하이브리드 조인용 컴퓨터 동기화는 OU 필터를 따르기 때문에, 클라이언트를 **동기화 방식별 OU**에 두어 어느 방식으로 올라갔는지 구분했습니다.

### 3. 결과

#### 3-1. sync01 가입

가입 전에 NIC(lab-internal 쪽 "Ethernet 2")를 고정 IP로 구성했습니다. 서브넷 마스크는 255.255.255.0, **기본 게이트웨이는 비움**, 기본 설정 DNS는 DC입니다(조회: 캡처 화면). 캡처의 IP 값은 가렸습니다. 변수 이름의 뜻은 [Hyper-V 실습 환경 글]({{ "/iam/hyperv-lab-environment/" | relative_url }})의 주소 계획에 있습니다.

[![sync01 IPv4 속성: 고정 IP(SYNC_IP), DNS는 DC(DC_IP)]({{ "/assets/images/2026/11/adj-01-sync01-ipv4.png" | relative_url }})]({{ "/assets/images/2026/11/adj-01-sync01-ipv4.png" | relative_url }}){:target="_blank"}

그다음 서버 관리자 → 로컬 서버에서 컴퓨터 이름을 `sionnote-sync01`로 바꾸고 멤버를 **도메인 `sionnote.local`** 로 선택했습니다. 이름을 바꾸기 전 이름은 설치 직후의 임의 이름(`WIN-…`)이었습니다.

[![컴퓨터 이름/도메인 변경: 이름과 도메인]({{ "/assets/images/2026/11/adj-02-join-dialog.png" | relative_url }})]({{ "/assets/images/2026/11/adj-02-join-dialog.png" | relative_url }}){:target="_blank"}

도메인 가입 권한이 있는 자격 증명을 입력하면(자격 증명 입력 화면은 캡처하지 않았습니다) "Welcome to the sionnote.local domain." 메시지가 뜹니다. 확인 후 재시작합니다.

[![도메인 가입 완료 메시지]({{ "/assets/images/2026/11/adj-03-welcome.png" | relative_url }})]({{ "/assets/images/2026/11/adj-03-welcome.png" | relative_url }}){:target="_blank"}

가입 뒤 DC에서 읽은 계정은 `CN=SIONNOTE-SYNC01,CN=Computers,DC=sionnote,DC=local`이고, 컴퓨터 암호가 설정된 시각은 2026-11-02 22:51입니다(조회). 캡처의 "Welcome" 메시지 시각(22:52)과 맞습니다.

#### 3-2. 클라이언트 상태(2026-11-04 오전)

2026-11-04 11:30 두 클라이언트의 콘솔과 ad01(컴퓨터 계정 위치)에서 읽은 값입니다.

| 항목 | cl10 | cl11 |
|---|---|---|
| 컴퓨터 이름·도메인 | SIONNOTE-CL10 · sionnote.local | SIONNOTE-CL11 · sionnote.local |
| PartOfDomain | True | True |
| AD 컴퓨터 계정 위치 | `OU=ConnectSync,OU=CloudSyncLab` | `OU=CloudSync,OU=CloudSyncLab` |

cl11의 외부용 NIC에는 게이트웨이가 있고 lab-internal NIC에는 없어서, 도메인 통신은 내부 NIC로, 인터넷 통신은 NAT NIC로 나뉩니다(조회).

### 4. 운영 판단

- **DNS가 먼저**: 가입 창에 도메인 이름을 쳤을 때 DC를 못 찾으면 "도메인 컨트롤러에 연결할 수 없다"는 계열의 오류가 납니다. 이 경우 포트(LDAP 389 등)를 열기 전에 NIC의 DNS가 DC인지부터 봅니다. 클라이언트에 NIC가 두 개일 때는 내부 NIC의 DNS가 DC여야 합니다. 이 랩에서도 IP 부여 직후 `Test-NetConnection`으로 LDAP 389를 시험했을 때 한 번 실패했다가 다시 하자 성공한 적이 있어서, 직후 시험은 몇 초 뒤 한 번 더 해 보는 편이 낫습니다.
- **어댑터 이름이 한글**: 한글 Windows에서 NIC 이름이 "이더넷", "이더넷 2"이므로 `-InterfaceAlias 'Ethernet'`처럼 영어 이름으로 지정하면 실패합니다. MAC 주소로 NIC를 고르는 편이 안전합니다.
- **되돌린 뒤 확인**: 체크포인트를 적용하면 PC는 과거 상태가 되지만 AD 컴퓨터 계정은 그대로입니다. 되돌린 직후 `nltest /sc_query:도메인`과 `Get-ADComputer`로 둘이 맞는지 확인합니다(앞 글 6절 사례).

### 5. 절차

#### 5-1. 사전 작업: sync01에 Windows Server 설치

도메인에 가입시키기 전에 VM에 OS를 설치합니다. Hyper-V 관리자에서 VM에 연결하면 설치 ISO로 부팅되어 아래 순서로 진행됩니다(2026-11-02 22:36~22:41, sync01).

1. **언어·시간·키보드**: 기본값(English (United States), US)을 그대로 두고 Next를 누릅니다.

[![설치 1단계: 언어, 시간 및 통화 형식, 키보드]({{ "/assets/images/2026/11/sync01-os-01-language.png" | relative_url }})]({{ "/assets/images/2026/11/sync01-os-01-language.png" | relative_url }}){:target="_blank"}

2. **Install now**를 누릅니다.

[![설치 2단계: Install now]({{ "/assets/images/2026/11/sync01-os-02-install-now.png" | relative_url }})]({{ "/assets/images/2026/11/sync01-os-02-install-now.png" | relative_url }}){:target="_blank"}

3. **운영 체제 선택**: 이 랩은 `Windows Server 2022 Standard Evaluation (Desktop Experience)`를 골랐습니다. 항목을 고르면 화면 아래 설명에 "전체 Windows 그래픽 환경을 설치하며 디스크 공간을 더 쓴다"는 취지의 문구(Description)가 나옵니다(조회).

[![설치 3단계: 운영 체제 선택(Standard Evaluation, Desktop Experience)]({{ "/assets/images/2026/11/sync01-os-03-edition.png" | relative_url }})]({{ "/assets/images/2026/11/sync01-os-03-edition.png" | relative_url }}){:target="_blank"}

4. **라이선스 약관**에 동의합니다. 이 설치 흐름에서는 제품 키를 묻는 화면이 없었습니다(조회).

[![설치 4단계: 라이선스 약관 동의]({{ "/assets/images/2026/11/sync01-os-04-license.png" | relative_url }})]({{ "/assets/images/2026/11/sync01-os-04-license.png" | relative_url }}){:target="_blank"}

5. **설치 유형**: Custom(새로 설치)을 고르면 디스크 선택 화면으로 넘어갑니다. Upgrade는 기존 OS가 실행 중일 때만 쓸 수 있습니다.

[![설치 5단계: 설치 유형(Upgrade 또는 Custom)]({{ "/assets/images/2026/11/sync01-os-05-install-type.png" | relative_url }})]({{ "/assets/images/2026/11/sync01-os-05-install-type.png" | relative_url }}){:target="_blank"}

6. **디스크 선택**: 60GB 빈 공간(Drive 0 Unallocated Space)을 선택하고 Next를 누르면 설치가 시작됩니다.

[![설치 6단계: 설치할 디스크 선택(60GB 빈 공간)]({{ "/assets/images/2026/11/sync01-os-06-disk.png" | relative_url }})]({{ "/assets/images/2026/11/sync01-os-06-disk.png" | relative_url }}){:target="_blank"}

설치가 끝나면 서버 관리자가 열립니다. 이어서 아래 도메인 가입 절차를 진행합니다.

#### 5-2. 도메인 가입

GUI 경로(문서 기준, sync01은 위 캡처로 확인)입니다.

1. **NIC DNS 지정**: 설정 → 네트워크 → 어댑터 옵션 변경 → 해당 NIC 속성 → IPv4 → "다음 DNS 서버 주소 사용"에 DC 주소를 입력합니다.
2. **서버**: 서버 관리자 → 로컬 서버 → 컴퓨터 이름 링크 → **변경** → 멤버: 도메인 → 도메인 이름 입력 → 자격 증명 → 확인 후 재시작(문서).
3. **클라이언트**: 설정 → 계정 → 회사 또는 학교 액세스 → 연결 → "이 디바이스를 로컬 Active Directory 도메인에 가입"(문서). 또는 제어판 → 시스템 → 컴퓨터 이름 변경.
4. **계정 위치 확인**: DC에서 Active Directory 사용자 및 컴퓨터 → 해당 OU를 열어 컴퓨터 계정을 확인합니다. 원하는 OU가 아니면 끌어서 옮깁니다.
5. **확인**: 가입한 PC에서 `nltest /sc_query:sionnote.local`(성공: `NERR_Success`).

```powershell
# 도메인 가입과 보안 채널 확인(PowerShell)
Get-CimInstance Win32_ComputerSystem | Select Name,Domain,PartOfDomain
nltest /sc_query:sionnote.local
```

### 6. 막힌 곳

- IP를 막 부여한 직후에는 `Test-NetConnection`의 LDAP 389가 실패했고, 잠시 뒤 재시험하자 성공했습니다(타이밍 문제로 보임, 추정: 당시 출력·캡처는 남기지 않음).

### 7. 정리·남은 일

- 다음 글: sync01에 Connect Sync를 설치하고 방화벽 규칙을 여는 과정.

### 부록. 사용한 명령과 출력

2026-11-04 11:30에 cl10·cl11 콘솔의 PowerShell에서 실행했습니다.

**가입 상태와 보안 채널**

```powershell
whoami
$c=Get-CimInstance Win32_ComputerSystem; "Computer=$($c.Name) Domain=$($c.Domain) PartOfDomain=$($c.PartOfDomain)"
nltest /sc_query:sionnote.local
```

```text
cl11 출력
Computer=SIONNOTE-CL11 Domain=sionnote.local PartOfDomain=True
플래그: 30 HAS_IP  HAS_TIMESERV  인증 서비스: Netlogon
트러스트된 DC 이름 \\sionnote-ad01.sionnote.local
트러스트된 DC 연결 상태 Status = 0 0x0 NERR_Success
명령을 완료했습니다.

cl10 출력
Computer=SIONNOTE-CL10 Domain=sionnote.local PartOfDomain=True
(cl10은 nltest를 실행하지 않았습니다.)
```

**NIC 구성(cl11)**

출력의 IP 값은 주소 계획의 변수 이름으로 바꿔 적었습니다(표기용 치환, 나머지는 원본).

```powershell
(Get-CimInstance Win32_OperatingSystem | % { "$($_.Caption) $($_.Version)" })
Get-NetIPConfiguration | % { "{0}: IPv4={1} GW={2} DNS={3}" -f $_.InterfaceAlias,($_.IPv4Address.IPAddress -join ','),($_.IPv4DefaultGateway.NextHop -join ','),($_.DNSServer.ServerAddresses -join ',') }
```

```text
Microsoft Windows 11 Enterprise 10.0.22631
이더넷: IPv4=<NAT_IP> GW=<NAT_GW> DNS=<NAT_GW>
이더넷 2: IPv4=<CL11_IP> GW= DNS=<DC_IP>
```

**컴퓨터 계정 위치와 암호 설정 시각(ad01)**

```powershell
Get-ADComputer -Filter * -Properties PasswordLastSet | Select Name,DistinguishedName,PasswordLastSet | ft -AutoSize -Wrap
```

결과는 [AD 구성 글]({{ "/iam/ad-domain-build/" | relative_url }})의 부록 표와 같습니다.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- (조회) sync01 IP 구성·가입 화면: 2026-11-02 22:47~22:52 사용자 캡처 원본
- (조회) sync01 OS 설치 화면(5-1): 사용자 캡처 원본
- (조회) 컴퓨터 계정의 위치·암호 설정 시각: ad01 `Get-ADComputer` (2026-11-04)
- (조회) cl10·cl11 가입 상태, cl11 NIC·보안 채널: 각 PC의 PowerShell (2026-11-04 11:30)
- (문서) [컴퓨터를 도메인에 가입시키기(서버·클라이언트)](https://learn.microsoft.com/windows-server/identity/ad-ds/manage/join-computer-to-domain)
- (문서) [AD DS 도메인 가입 전제: DNS로 DC를 찾을 수 있어야 함(SConfig 문서의 설명)](https://learn.microsoft.com/windows-server/administration/server-core/server-core-sconfig#join-a-domain-or-workgroup)

</details>
