---
title: "[Study] 클라우드 학습 용어 전집과 영상·자료"
date: 2026-10-31 10:15:00 +0900
categories: [study]
phase: 부록
seq: 2
tags: [Study, 용어집, Azure, Microsoft 365, Entra ID, Intune, 학습 자료]
excerpt: "모르는 용어가 막힐 때 펼치는 곳. 클라우드 용어 200여 개를 원어와 온프레미스 비교로, 한글 우선 영상과 함께"
---

공부하다 15분 넘게 막히면 대개 모르는 용어 하나 때문입니다. 클라우드 용어를 영어 원어 기준으로 영역별로 모으고 온프레미스로 보면 무엇인지 함께 적어 두었으니, 막힐 때 여기서 찾고 넘어가면 됩니다.

## 요약

- 클라우드 용어 225개를 8개 영역으로 나눠 원어와 온프레미스 비교로 정리함
- 막히는 용어는 해당 영역만 펼쳐 찾고, 온프레미스 비교는 감을 잡는 데만 씀
- 여러 영역의 한글 영상과 SharePoint·Teams 영문 영상은 확인 불가

12주 학습 로드맵의 부록입니다. 이전: [온프레미스 ↔ 클라우드 대응표]({{ "/study/onprem-cloud-mapping/" | relative_url }}) · [전체 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 용어 전집

화살표(→) 뒤는 온프레미스나 기존 개념으로 보면 무엇에 해당하는지(비교 개념)이며, 일대일로 같지 않은 경우가 많습니다.

#### 클라우드 일반

<details markdown="1">
<summary>클라우드 일반 용어 펼쳐 보기 (19개)</summary>

- **Cloud computing** · 인터넷으로 컴퓨팅 자원을 쓴 만큼 내고 빌려 쓰는 모델 → 서버실 임대
- **IaaS (Infrastructure as a Service)** · VM·네트워크·디스크를 빌림. OS부터는 고객 관리 → 서버 하드웨어 임대
- **PaaS (Platform as a Service)** · 런타임까지 제공받고 앱과 데이터만 관리 → OS 패치 없이 쓰는 DB 서버
- **SaaS (Software as a Service)** · 완성된 앱을 구독해서 사용 → 설치형 메일 서버 대신 메일 서비스
- **Public · Private · Hybrid cloud** · 공용 클라우드, 사설 클라우드, 둘을 연결한 구성 → 자체 데이터센터 + 외부
- **Region** · 데이터센터가 모인 지리적 지역 → 데이터센터가 있는 도시
- **Availability Zone (AZ)** · 한 Region 안에서 전원·냉각·네트워크가 분리된 데이터센터 → 같은 단지의 다른 서버실
- **Region pair** · 재해 복구를 위해 짝지어진 두 Region → DR 사이트
- **SLA (Service Level Agreement)** · 서비스 가동률 보장 수준 → 유지보수 계약의 가용성 조건
- **HA (High Availability)** · 일부 구성요소가 장애여도 서비스가 이어지는 설계 → 클러스터 · DAG
- **DR (Disaster Recovery)** · 사이트 전체 장애에서의 복구 → DR 센터
- **RPO (Recovery Point Objective)** · 허용 가능한 데이터 손실 시점 → 백업 주기
- **RTO (Recovery Time Objective)** · 허용 가능한 복구 시간 → 복구 목표 시간
- **Scalability · Elasticity** · 확장 가능성 · 사용량에 따라 자동으로 늘리고 줄이는 성질 → 서버 증설
- **CapEx · OpEx** · 자본 지출 · 운영 지출. 클라우드는 OpEx 중심 → 장비 구매 vs 월 사용료
- **Shared responsibility model** · 클라우드 사업자와 고객의 책임 경계 → 서버실 보안은 건물주, 서버 설정은 나
- **Zero Trust** · Verify explicitly · Use least privilege · Assume breach → 내부망 신뢰 모델의 반대
- **Least privilege** · 필요한 최소 권한만 부여 → 최소 권한 원칙
- **Defense in depth** · 여러 계층에 방어를 겹쳐 둠 → 다층 보안

</details>

#### Entra ID와 신원

<details markdown="1">
<summary>Entra ID와 신원 용어 펼쳐 보기 (56개)</summary>

- **Microsoft Entra ID** · Microsoft의 클라우드 ID·접근 관리 서비스(구 Azure AD) → AD DS (구조는 다름)
- **Tenant** · 한 조직 전용 Entra ID 인스턴스. identity boundary → AD 포리스트
- **Directory** · Tenant가 가진 객체 저장소 → AD 데이터베이스
- **Initial domain** · 처음 만들어지는 `*.onmicrosoft.com` 도메인 → 내부 도메인 이름
- **Custom domain** · DNS로 소유를 확인해 추가한 회사 도메인 → UPN suffix
- **UPN (User Principal Name)** · `user@domain` 형태의 로그인 이름 → UPN
- **Object ID** · 객체의 고유 식별자(GUID) → objectGUID
- **User (Member · Guest)** · 내부 사용자 · 외부 협업 사용자 → 사용자 · 외부 계정
- **Cloud-only user · Synced user** · 클라우드에서 만든 계정 · 온프레미스에서 동기화된 계정 → 로컬 계정 · 동기화 계정
- **Source of authority** · 객체의 원본을 어디서 관리하는가 → 마스터 디렉터리
- **Group (Security · Microsoft 365)** · 권한용 그룹 · 협업(메일·Teams·SharePoint)용 그룹 → Security Group · 배포 그룹
- **Assigned · Dynamic membership** · 직접 지정 · 규칙 기반 자동 구성(Entra ID P1) → 수동 편입 vs 스크립트
- **Role-assignable group** · Entra role을 할당할 수 있는 특수 그룹 → 권한 그룹
- **Administrative unit (AU)** · 관리 권한을 일부 객체에만 위임하는 범위 → 위임용 OU (정책 상속 없음)
- **Entra role** · Entra 리소스와 M365 서비스 관리 권한 → AD 관리 위임
- **Global Administrator** · 테넌트 전체 관리 권한을 가진 최상위 Entra role → Enterprise Admins
- **Authentication (AuthN)** · 누구인지 확인 → 로그온
- **Authorization (AuthZ)** · 무엇을 할 수 있는지 결정 → ACL
- **SSO (Single Sign-On)** · 한 번 로그인으로 여러 앱 사용 → 도메인 로그온
- **MFA (Multi-Factor Authentication)** · 둘 이상의 요소로 확인 → 스마트카드 · OTP
- **Passwordless · Passkey · FIDO2** · 비밀번호 없이 하드웨어·기기 기반 키로 인증 → 스마트카드 인증
- **WHfB (Windows Hello for Business)** · 기기에 묶인 키와 PIN·생체로 로그인 → PIN 기반 스마트카드
- **TAP (Temporary Access Pass)** · 최초 인증 수단 등록용 임시 코드 → 임시 비밀번호
- **SSPR (Self-Service Password Reset)** · 사용자가 직접 비밀번호를 재설정 → 암호 재설정 포털
- **Authentication methods policy** · 쓸 수 있는 인증 수단을 정하는 정책 → 인증 정책
- **Authentication strength** · 어떤 강도의 MFA를 요구할지 지정(예: phishing-resistant) → 요구 인증 수준
- **Token (access · ID · refresh)** · 로그인 결과로 받는 증명. 앱은 이를 보고 접근 허용 → Kerberos 티켓
- **PRT (Primary Refresh Token)** · 등록된 디바이스에서 SSO를 가능하게 하는 토큰 → TGT와 비슷한 역할
- **OAuth 2.0** · 접근 권한을 위임하는 표준 → 위임(delegation)
- **OIDC (OpenID Connect)** · OAuth 2.0 위에서 로그인 확인(ID token)을 더한 표준 → 인증 프로토콜
- **SAML** · XML 기반의 오래된 SSO 표준 → AD FS가 쓰던 방식
- **WS-Federation** · 웹 기반 페더레이션 표준(AD FS에서 흔히 사용) → AD FS 신뢰
- **Kerberos** · 티켓 기반 인증(온프레미스 AD) → 동일
- **App registration** · 앱을 Entra ID에 등록한 정의(application object) → 앱 등록 · SPN
- **Enterprise application** · 테넌트 안에서 앱을 쓰게 하는 인스턴스(service principal) → 앱 접근 설정
- **Service principal** · 앱이 테넌트에서 갖는 신원 → 서비스 계정
- **Managed identity (system · user-assigned)** · Azure 리소스가 쓰는 자동 관리 신원 → gMSA
- **Delegated · Application permission** · 사용자 대신 접근 · 앱 단독 접근 권한 → 대리 · 서비스 권한
- **Admin consent** · 관리자가 앱 권한을 조직 전체에 승인 → 앱 승인
- **Microsoft Graph** · M365·Entra를 다루는 통합 REST API → LDAP + 관리 API
- **B2B collaboration** · 외부 사용자를 Guest로 초대해 협업 → 외부 사용자 계정
- **Cross-tenant access settings** · 다른 테넌트와의 신뢰·협업 정책 → Forest trust 정책
- **Conditional Access (CA)** · 조건에 따라 접근을 차단·허용하는 정책 엔진(P1) → 방화벽 규칙 + GPO 로그온 제한
- **Named location** · 정책에서 쓰는 신뢰 IP·국가 범위 → 사내 IP 대역
- **Report-only mode** · 정책을 평가만 하고 강제하지 않는 모드 → 시뮬레이션 모드
- **Security defaults** · Entra ID의 기본 보호 설정(무료). CA와 함께 쓰지 않음 → 기본 보안 템플릿
- **Legacy authentication** · MFA를 지원하지 않는 옛 프로토콜(IMAP·POP·SMTP AUTH 등) → 기본 인증
- **Emergency access (break-glass) account** · 정책 사고에 대비한 비상용 클라우드 전용 관리자 → 비상 관리자 계정
- **Identity Protection** · 위험(risk) 기반 보호. sign-in risk · user risk (P2) → 이상 로그온 탐지
- **PIM (Privileged Identity Management)** · 관리자 권한을 필요할 때만 활성화(P2 또는 Microsoft Entra ID Governance) → tiered admin 운영
- **Eligible · Active assignment** · 자격만 있음 · 현재 활성화됨 → 상시 vs 임시 권한
- **JIT (Just-in-time)** · 필요한 시간 동안만 권한 부여 → 임시 승격
- **Access review** · 권한 보유자를 주기적으로 재검토 → 권한 재인증
- **Entitlement management · Access package** · 접근 권한 묶음의 요청·승인·만료 관리 → 접근 요청 시스템
- **Lifecycle Workflows** · 입사·이동·퇴사 때 자동 작업 실행 → 계정 수명주기 자동화
- **Entra ID Free · P1 · P2 · Governance** · 기능 등급. CA는 P1, Identity Protection은 P2, PIM은 P2 또는 ID Governance → 에디션

</details>

더 깊은 신원 용어: [IAM 용어집]({{ "/iam/entra-id-glossary/" | relative_url }})

#### 하이브리드 ID

<details markdown="1">
<summary>하이브리드 ID 용어 펼쳐 보기 (18개)</summary>

- **Hybrid identity** · 온프레미스 AD와 Entra ID를 연결해 같은 계정으로 사용 → 포리스트 연계
- **Microsoft Entra Connect Sync** · 서버에 설치하는 동기화 엔진(구 Azure AD Connect) → 디렉터리 동기화 서버
- **Microsoft Entra Cloud Sync** · 경량 에이전트 기반 동기화. 다중 포리스트에 유리 → 경량 동기화
- **Sync cycle (Delta · Initial)** · 변경분 동기화 · 전체 동기화. 기본 주기 30분 → 복제 주기
- **sourceAnchor · ImmutableId** · 온프레미스 객체와 클라우드 객체를 잇는 고정 키 → 객체 매칭 키
- **Filtering (OU · attribute)** · 동기화 대상 범위를 OU나 속성으로 제한 → 동기화 범위
- **PHS (Password Hash Synchronization)** · 비밀번호 해시를 한 번 더 해시해 Entra ID로 동기화. 인증은 클라우드가 수행 → 해시 사본 보유
- **PTA (Pass-through Authentication)** · 로그인 요청을 온프레미스 에이전트가 DC에 전달해 검증. 해시를 클라우드에 저장하지 않음 → 온프레미스 대리 확인
- **PTA agent** · PTA에서 DC에 인증을 전달하는 경량 소프트웨어(3대 권장) → 인증 프록시
- **Federation (AD FS · WAP)** · 인증을 온프레미스 IdP에 위임. AD FS와 WAP 서버 필요 → AD FS
- **Seamless SSO** · 사내 도메인 PC에서 Kerberos로 자동 로그인(PHS·PTA와 함께) → 도메인 SSO
- **Staged rollout** · 일부 사용자만 먼저 클라우드 인증으로 전환 → 단계적 전환
- **Password writeback** · 클라우드에서 바꾼 비밀번호를 온프레미스 AD에 반영 → 암호 재설정 연계
- **Entra Connect Health** · 동기화·AD FS 상태를 클라우드에서 모니터링 → 모니터링 에이전트
- **Microsoft Entra Domain Services** · Azure에서 제공하는 관리형 AD DS(도메인 가입·LDAP·Kerberos) → 관리형 DC
- **Entra registered · joined · hybrid joined** · 디바이스 등록 방식 세 가지 → 도메인 가입 상태
- **SCP (Service Connection Point)** · hybrid join 때 디바이스가 테넌트를 찾는 AD 객체 → 서비스 연결 지점
- **Microsoft Defender for Identity** · DC에 센서를 설치해 온프레미스 AD 공격을 탐지 → AD 보안 감시

</details>

인증 방식 상세 비교: [하이브리드·외부 사용자·라이선스·운영]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})

#### Microsoft 365

<details markdown="1">
<summary>Microsoft 365 용어 펼쳐 보기 (30개)</summary>

- **Microsoft 365 admin center** · M365 구독·사용자·서비스를 관리하는 통합 콘솔 → 관리 콘솔
- **SKU · License · Service plan** · 상품 단위 · 사용자에게 할당하는 사용 권한 · 그 안의 개별 서비스 → CAL
- **Group-based licensing** · 그룹에 license를 할당해 멤버에게 자동 적용(Entra ID P1 이상, 또는 Office 365 E3·A3·G3 이상) → 그룹 기반 부여
- **MX · SPF · DKIM · DMARC** · 수신 서버 · 발신 허용 선언 · 서명 · 실패 시 처리 정책 → 메일 DNS 레코드
- **Autodiscover** · 메일 클라이언트가 설정을 자동으로 찾는 서비스 → 동일
- **Exchange Online** · 클라우드 메일·일정 서비스 → Exchange Server
- **EOP (Exchange Online Protection)** · 클라우드 스팸·악성코드 필터 → 메일 게이트웨이
- **Mailbox types** · User · Shared · Room · Equipment → 사서함 유형
- **Distribution group · Mail-enabled security group · M365 group** · 메일 배포 · 메일 배포+권한 · 협업 전체 → 배포 그룹 · 보안 그룹
- **Accepted domain** · 수신을 허용하는 도메인 → 동일
- **Mail flow rule (transport rule)** · 조건에 따라 메일을 처리하는 규칙 → Transport rule
- **Connector** · 파트너나 온프레미스와의 메일 경로 정의 → Send · Receive Connector
- **Message trace** · 메일의 전달 경로와 상태 추적 → 메시지 추적
- **Quarantine** · 위험 메일을 격리하는 영역 → 격리함
- **Exchange hybrid · HCW** · 온프레미스 Exchange와 Online을 함께 쓰는 구성 · 구성 마법사 → 공존 구성
- **Retention policy · Litigation hold** · 보존·삭제 정책(Microsoft Purview에서 관리) · 사서함마다 거는 법적 보존(Exchange Online Plan 2 필요) → 보존 정책
- **SharePoint Online · Site** · 문서·콘텐츠 협업 서비스 · 그 안의 사이트 → 인트라넷 · 파일 서버
- **Team site · Communication site · Hub site** · 팀용 · 공지용 · 사이트를 묶는 허브 → 부서 공유
- **OneDrive for Business** · 개인 파일 저장소 → 홈 폴더
- **Team · Channel (Standard · Private · Shared)** · Teams의 팀과 채널 유형 → 프로젝트 방
- **Owners · Members · Visitors** · 사이트 권한 그룹 세 가지 → 폴더 ACL 그룹
- **Sharing link** · Anyone · People in your organization · People with existing access · Specific people → 공유 URL
- **External sharing · Guest access** · 조직 밖 사용자와 공유 · Guest 초대 → 외부 공유
- **Sensitivity label** · 문서·메일 분류와 보호(암호화) 표시 → 문서 보안 등급
- **Retention label** · 항목별 보존 규칙 → 보존 정책
- **DLP (Data Loss Prevention)** · 민감 정보 유출 방지 정책 → 정보 유출 방지
- **Microsoft Purview** · 데이터 보호·규정 준수 서비스 모음 → 컴플라이언스 도구
- **eDiscovery** · 법적 요구에 맞춰 콘텐츠 검색·보존 → 전자 증거 검색
- **Unified audit log** · M365 전반의 감사 로그 → 감사 로그
- **Service health · Message center** · 서비스 장애 현황 · 변경 예고 공지 → 벤더 공지

</details>

#### Intune와 디바이스

<details markdown="1">
<summary>Intune와 디바이스 용어 펼쳐 보기 (18개)</summary>

- **Microsoft Intune** · 클라우드 디바이스·앱 관리 서비스 → MECM + GPO 일부
- **MDM (Mobile Device Management)** · 디바이스 전체 등록·관리 → 디바이스 관리
- **MAM (Mobile Application Management)** · 앱 단위 데이터 보호(BYOD에서 사용) → 앱 컨테이너
- **Enrollment** · 디바이스를 Intune에 등록 → 클라이언트 등록
- **Windows Autopilot** · 신규 PC를 클라우드로 프로비저닝 → OSD · 이미징
- **Compliance policy** · 디바이스가 만족해야 할 기준. CA와 연동 → 컴플라이언스 점검
- **Configuration profile · Settings catalog** · 디바이스 설정 배포 · 설정 항목 검색형 구성 → GPO
- **Administrative templates** · ADMX 기반 설정 → GPO 관리 템플릿
- **Group Policy analytics** · GPMC에서 XML로 내보낸 기존 GPO를 가져와 Intune 지원 여부 확인 → GPO 마이그레이션 도구
- **App protection policy** · 앱 데이터 복사·붙여넣기·저장 제한 → 앱 정책
- **Win32 app (.intunewin)** · 설치형 앱을 패키징해 배포 → MECM 앱 배포
- **Update ring · Windows Autopatch** · 업데이트 배포 링 · 업데이트 관리 서비스 → WSUS · MECM 패치
- **Co-management · Tenant attach** · Intune과 MECM 병행 · MECM 디바이스를 클라우드에 연결 → 병행 운영
- **Remediations** · 탐지 + 교정 스크립트 → DCM
- **Device filter** · 정책 대상을 디바이스 속성으로 좁힘 → 대상 필터
- **Intune Certificate Connector** · 온프레미스 CA에서 인증서를 가져다 배포 → AD CS 연계
- **SCEP · PKCS** · Intune의 인증서 배포 프로필 방식 → 자동 등록
- **Cloud PKI** · Intune에서 제공하는 클라우드 인증서 발급 서비스(Microsoft Cloud PKI). 2026년 7월부터 Microsoft 365 E5·E7에 포함, 그 밖의 플랜은 Intune Suite 별도 구독 → 클라우드 CA

</details>

#### Azure 인프라

<details markdown="1">
<summary>Azure 인프라 용어 펼쳐 보기 (48개)</summary>

- **Subscription** · 청구·접근·한도 경계. 하나의 Tenant를 신뢰 → 예산 계약
- **Management group** · 여러 구독을 묶는 상위 단위 → 최상위 OU
- **Resource group** · 리소스를 담는 논리적 컨테이너 → 서버 그룹 폴더
- **Resource** · VM·Storage·VNet 같은 개별 서비스 인스턴스 → 개별 서버 · 서비스
- **ARM (Azure Resource Manager)** · 모든 도구가 거치는 Azure 관리 계층 → 단일 관리 API
- **ARM template · Bicep** · 리소스를 코드로 선언해 배포(Bicep은 ARM의 간결한 언어) → 배포 스크립트
- **Terraform** · 여러 클라우드에서 쓰는 IaC 도구 → 배포 자동화
- **Resource provider** · 서비스별 관리 기능을 제공하는 단위(Microsoft.Compute 등) → 서비스 모듈
- **Tags** · 이름·값 쌍 메타데이터(비용·소유 구분) → 라벨
- **Resource lock** · CanNotDelete · ReadOnly로 삭제·수정 방지 → 삭제 금지 설정
- **VM (Virtual Machine)** · 가상 머신 → Hyper-V VM
- **VM size · series** · VM의 CPU·메모리 사양 묶음 → 서버 사양
- **Managed disk** · Azure가 관리하는 VM 디스크 → VHD
- **Availability set** · 한 데이터센터 내 장애·업데이트 도메인 분산 → 랙 분산
- **VMSS (VM Scale Set)** · 동일 VM을 자동으로 늘리고 줄이는 그룹 → 서버 팜
- **Azure Compute Gallery** · 이미지 버전 관리·공유 → 골든 이미지 저장소
- **Azure Bastion** · 공용 IP 없이 포털에서 RDP·SSH 접속 → 점프 서버
- **Azure Hybrid Benefit** · 기존 Windows Server·SQL 라이선스를 적용해 비용 절감 → 라이선스 이전
- **Reserved Instance · Spot VM** · 1~3년 약정 할인(Azure Reservations의 VM 예약. 시간당 지출을 약정하는 savings plan도 있음) · 중단 가능한 저가 VM → 약정 · 유휴 자원
- **Azure Update Manager** · 서버 패치 관리 → WSUS · MECM 패치
- **Azure Arc** · 온프레미스·다른 클라우드 서버를 Azure 리소스처럼 관리 → 통합 관리 에이전트
- **App Service · Functions · AKS** · 웹앱 PaaS · 서버리스 함수 · 관리형 Kubernetes → 웹 서버 · 스케줄러 · 컨테이너 플랫폼
- **Storage account** · 스토리지 서비스를 담는 계정 → 스토리지 어레이
- **Blob · Azure Files · Queue · Table** · 객체 · SMB 파일 공유 · 메시지 큐 · NoSQL 테이블 → 오브젝트 · 파일 서버
- **LRS · ZRS · GRS · GZRS (RA-)** · 스토리지 복제 수준(읽기 가능 보조 복제는 RA-) → 복제 구성
- **Access tier (Hot · Cool · Cold · Archive)** · 접근 빈도에 따른 저장 계층 → 스토리지 티어링
- **SAS (Shared Access Signature)** · 제한된 권한과 만료를 가진 접근 URL·토큰 → 임시 접근 키
- **Access key** · 스토리지 계정 전체 권한 키 → 관리자 키
- **Azure File Sync** · 온프레미스 파일 서버와 Azure Files 동기화 → DFS 복제
- **Azure Backup · Recovery Services vault** · 백업 서비스 · 백업 저장소 → 백업 솔루션
- **ASR (Azure Site Recovery)** · 다른 Region으로 복제해 장애 시 전환 → DR 복제
- **VNet · Subnet · CIDR** · 가상 네트워크 · 그 안의 구획 · 주소 표기 → VLAN · 서브넷
- **NSG (Network Security Group)** · 서브넷·NIC에 거는 stateful 허용·차단 규칙 → L4 ACL
- **ASG (Application Security Group)** · 앱 단위로 VM을 묶어 NSG 규칙에 사용 → 서버 그룹
- **UDR · Route table** · 사용자 정의 경로 → 정책 라우팅
- **VNet peering** · VNet 간 직접 연결(전이적이지 않음) → 라우터 직결
- **VPN Gateway (S2S · P2S)** · IPsec VPN. 사이트 간 · 지점 대 사이트 → VPN 장비
- **ExpressRoute** · 통신사업자를 통한 전용 회선 → 전용선
- **Virtual WAN** · 여러 지점을 hub로 묶어 관리 → WAN 허브
- **Hub-and-spoke** · 공용 hub와 개별 spoke VNet 구성 → 중앙 집중형 토폴로지
- **Azure Firewall** · 중앙 관리형 방화벽 서비스 → 중앙 방화벽
- **Load Balancer · Application Gateway · WAF** · L4 분산 · L7 분산 · 웹 방화벽(Web Application Firewall. 아래 "보안, 거버넌스, 모니터링" 영역의 Well-Architected Framework와 다름) → L4 · L7 스위치
- **Front Door · Traffic Manager** · 전역 L7 진입점 · DNS 기반 분산 → GSLB
- **Private Endpoint (Private Link)** · PaaS를 VNet의 사설 IP로 연결 → 내부 전용 접속
- **Service Endpoint** · VNet 신원을 서비스에 전달(트래픽은 공용 엔드포인트) → 접근 제한
- **Azure DNS · Private DNS zone** · 공용 DNS 호스팅 · VNet 내부 DNS 영역 → DNS 서버
- **NAT Gateway** · 서브넷의 고정 아웃바운드 IP 제공 → NAT 장비
- **DDoS Protection** · 대규모 트래픽 공격 방어 → 안티 DDoS

</details>

#### 보안, 거버넌스, 모니터링

<details markdown="1">
<summary>보안, 거버넌스, 모니터링 용어 펼쳐 보기 (28개)</summary>

- **Azure RBAC** · Azure 리소스 접근을 역할로 부여 → 위임 권한
- **Role definition · Role assignment · Scope** · 역할 정의 · 보안 주체에 할당 · 적용 범위 → 권한 구조
- **Owner · Contributor · Reader · User Access Administrator** · 전체+할당 · 전체 · 읽기 · 접근 권한 관리 → 기본 관리 역할
- **Azure Policy** · 리소스 상태를 평가·강제하는 정책 → GPO + 컴플라이언스 점검
- **Policy effect (Audit · Deny · Modify · DeployIfNotExists)** · 감사 · 차단 · 속성 수정 · 없으면 배포 → 정책 동작
- **Initiative** · 여러 Policy를 묶은 단위 → GPO 묶음
- **Microsoft Defender for Cloud** · 보안 상태 점검과 워크로드 보호 → 보안 점검 도구
- **CSPM · CWPP** · 클라우드 보안 상태 관리 · 클라우드 워크로드 보호 → 취약점 점검 · 호스트 보호
- **Secure Score** · 보안 상태 점수 → 보안 점수
- **Key Vault** · 비밀·키·인증서 보관과 수명주기 관리. 접근 제어는 Azure RBAC 권장(access policy는 레거시) → HSM · 키 관리 서버
- **Cost Management · Budget** · 비용 분석 · 예산과 알림 → 예산 관리
- **Azure Advisor** · 비용·보안·성능·안정성 권고 → 점검 리포트
- **CAF (Cloud Adoption Framework)** · 클라우드 도입 전체 가이드 → 도입 방법론
- **Well-Architected Framework (WAF)** · 워크로드 설계 품질 기준(5개 pillar). 위 "Azure 인프라" 영역의 Web Application Firewall과 다름 → 설계 점검표
- **Landing zone** · 구독·네트워크·거버넌스를 미리 갖춘 기반 환경 → 표준 환경
- **Azure Monitor** · Azure 모니터링 통합 서비스 → 모니터링 시스템
- **Metrics · Logs** · 시계열 수치 · 상세 이벤트 → 성능 카운터 · 이벤트 로그
- **Log Analytics workspace** · 로그를 모아 쿼리하는 저장소 → 로그 서버
- **KQL (Kusto Query Language)** · Log Analytics·Sentinel에서 쓰는 쿼리 언어 → SQL과 유사한 쿼리
- **Diagnostic settings** · 리소스 로그를 workspace·스토리지·Event Hub로 보내는 설정 → 로그 전송 설정
- **Activity log** · 구독 수준의 control plane 작업 기록 → 관리 작업 감사 로그
- **Alert rule · Action group** · 조건 기반 알림 · 알림·자동화 수신 대상 → 모니터링 알림
- **Application Insights** · 앱 성능 모니터링 → APM
- **Workbook** · 시각화 리포트 → 대시보드
- **Microsoft Sentinel** · 클라우드 SIEM·SOAR. 2027-03-31 이후 Microsoft Defender portal에서만 사용 → SIEM
- **SIEM · SOAR** · 보안 이벤트 수집·분석 · 대응 자동화 → 관제 · 자동 대응
- **Data connector · Analytics rule · Incident · Playbook** · 수집 연결 · 탐지 규칙 · 사건 · 자동 대응 → SIEM 구성요소
- **Microsoft Defender XDR** · Defender 제품군의 통합 탐지·대응 포털 → 통합 보안 콘솔

</details>

#### 관리 도구

<details markdown="1">
<summary>관리 도구 용어 펼쳐 보기 (8개)</summary>

- **Azure portal · Entra admin center · M365 admin center · Intune admin center** · 서비스별 웹 관리 콘솔 → 관리 콘솔
- **Cloud Shell** · 브라우저 안에서 쓰는 PowerShell·Bash → 원격 쉘
- **Azure CLI** · Azure 명령줄 도구(`az`) → CLI
- **Az PowerShell** · Azure 관리용 PowerShell 모듈 → PowerShell 모듈
- **Microsoft Graph PowerShell** · Entra·M365 관리용 PowerShell 모듈 → AD 모듈
- **ExchangeOnlineManagement** · Exchange Online 관리 모듈(`Connect-ExchangeOnline`) → Exchange 관리 쉘
- **Graph Explorer** · Microsoft Graph API를 웹에서 시험하는 도구 → API 테스트 도구
- **AzureAD · MSOnline 모듈** · 은퇴(retire)한 옛 PowerShell 모듈(MSOnline은 2025년 4~5월에 동작 중지, AzureAD는 2025년 7월 초부터 은퇴 진행). 후속은 Microsoft Graph PowerShell(신규 학습은 이것 중심)과 Microsoft Entra PowerShell(AzureAD 모듈과 98% 넘게 호환) → 옛 AD 연동 모듈

</details>

### 2. 영상·자료 (한글 우선)

아래 영상은 직접 열어 확인했고(2026-11-01), 채널과 길이는 확인한 항목에만 적었습니다.

#### 한글 유튜브

- **Azure 개요**
    - [Az-900 Azure Fundamentals 1주차](https://www.youtube.com/watch?v=GgKAkAWLnPw): Microsoft Developer Korea, 1시간 38분, 2021년. 클라우드 개념(IaaS·PaaS·SaaS, 리전, 가용성, 소비 기반 요금). 서비스 이름과 화면이 지금과 다를 수 있습니다.
    - [Az-900 Azure Fundamentals 2주차](https://www.youtube.com/watch?v=892Nhkhwk4A): 같은 시리즈, 1시간 56분. 핵심 서비스(데이터베이스, 스토리지, 네트워크, 가상 머신·컨테이너)
    - [마이크로소프트 Azure 900 자격증, 함께 공부해 볼까요?](https://www.youtube.com/watch?v=iFWMKPnXMbo): 투마일스, 25분, 2022년. 클라우드 컴퓨팅이란, Azure란, 핵심 Azure 서비스, Azure 계정
- **Intune**
    - [\[MS Intune 기초편\] 사용자관리 - 인튠이란?](https://www.youtube.com/watch?v=7_dRLhnPwD0): 전라북도교육청 미래교육과 제작, 5분. 디바이스, 사용자 계정, 앱 관리 개요
    - [\[MS Intune 기초편\] 사용자관리 - 인튠 계정 암호 변경](https://www.youtube.com/watch?v=Kp5N_coWcfs): 같은 시리즈, 1분. 사용자를 검색해 임시 암호로 재설정
    - [교육용 인튠 튜토리얼](https://www.youtube.com/watch?v=QunVzLs4ulE): Microsoft Education Korea, 5분. 교육용 Intune 빠른 구성(그룹, 앱 선택, 설정), 스토어 앱 추가

> 확인 불가: Entra ID, 하이브리드 ID, Conditional Access, M365 관리, Exchange Online, Azure 네트워크, AZ-104 영역의 한글 유튜브는 유튜브에서 영역별로 검색했지만 찾지 못했습니다(2026-11-01 기준). 아래 한국어 공식 자료를 먼저 보고, 영어 영상은 한국어 자막(자동 번역)을 켠 채 용어 전집과 함께 보세요.

#### 한국어 공식 자료

- [Microsoft Korea Azure (All about Azure)](https://www.microsoft.com/ko-kr/azureall): 온디맨드 웨비나와 Azure Training Day(무료 등록)
- [Azure 교육 (Microsoft Learn, 한국어)](https://learn.microsoft.com/ko-kr/training/azure/): Azure 기본 사항 학습 경로와 Virtual Training Days
- [Microsoft Entra (Microsoft Adoption, 한국어)](https://adoption.microsoft.com/ko-kr/microsoft-security/entra/): Entra 학습 경로, 인증, 배포 문서 안내

한국어 번역 용어가 어색하면 영어 원문 페이지(URL의 `ko-kr`를 `en-us`로 바꿔서)에서 원어를 확인하세요.

한글 유튜브를 직접 찾을 때 쓸 검색어:

- "엔트라 ID 하이브리드", "Entra Connect 설치", "조건부 액세스 설정", "M365 관리자 센터 강의"
- "Exchange Online 관리", "Azure 가상 네트워크 NSG", "AZ-104 한국어 강의"

#### 영문 영상 (한글이 없는 영역의 보완)

자막은 자동 생성이라 세부 표현은 영상과 다를 수 있습니다.

<details markdown="1">
<summary>영문 영상 목록 펼쳐 보기 (28건)</summary>

- **Azure 개요**
    - [AZ-900 Course introduction](https://www.youtube.com/watch?v=orwWx0_KEcA): Microsoft Learn, 3분. 과정 소개와 세 세션 구성
    - [AZ-900: Azure Fundamentals Course with 2026 Updates](https://www.youtube.com/watch?v=yhzCNQfX3RE): Cloud360 Training, 6분. 2026년 AZ-900 개정 사항과 공부 순서 안내(과정 본편은 아님)
- **Entra ID**
    - [Understand Microsoft Entra ID (AZ-104 공식 2편)](https://www.youtube.com/watch?v=iQfhi0712bM): Microsoft Learn, 42분. 테넌트, 사용자, 그룹, 라이선스, Free·P1·P2 차이
- **하이브리드 ID**
    - [Identity Architecture: Microsoft Entra Connect](https://www.youtube.com/watch?v=F0ldcCfCWNw): Microsoft Azure, 4분, 2020년. connector space, metaverse 구조와 30분 주기 동기화
    - [Entra ID Connect installation for hybrid join](https://www.youtube.com/watch?v=RPj53B7rxYU): Dean Ellerby, 16분, 2024년. Connect 설치(빠른 설정)와 동기화 화면
    - [How to Configure Microsoft Entra Hybrid Join Device](https://www.youtube.com/watch?v=_vA5_OJPcTk): MSFT WebCast, 12분, 2025년. SCP 구성, delta sync, hybrid join 확인
- **인증 보안**
    - [Enforce MFA with Conditional Access (Step-by-Step Lab)](https://www.youtube.com/watch?v=MIvuAHIVTT4): CyberMax, 5분. MFA 강제 정책 생성과 테스트
    - [Entra ID Security: Identity Perimeter, Conditional Access, MFA & PIM](https://www.youtube.com/watch?v=4mTV4nb5Ex4): m365 Show, 19분. 개념 중심
    - [Entra ID Security: MFA, Conditional Access & Risk Protection](https://www.youtube.com/watch?v=q-OkGHwXAj0): KryptoMindz, 9분. 위험 기반 보호, 보고 전용 모드, P2 범위
- **M365 관리**
    - [Microsoft 365 Admin Centre, Intune, EntraID, Exchange 연동 개요](https://www.youtube.com/watch?v=o8bdHkxw-Es): Tech's World, 54분. 라이선스, 테넌트, Entra 등 관리 센터 메뉴 위주(Intune·Exchange는 짧게)
- **Exchange**
    - [How to Use Exchange Online Admin Center](https://www.youtube.com/watch?v=J0OWaStDkMc): 28분. 사서함, 공유 사서함 등 관리 센터 작업
    - [Microsoft 365: Creating and Managing User Mailboxes](https://www.youtube.com/watch?v=yvhwHjNVMvw): 12분. 사용자 사서함 생성과 관리
    - [Beginners Tutorial for Exchange Online & Microsoft 365 Administration](https://www.youtube.com/playlist?list=PLUZTRmXEpBy0W9bJNme2P9h5XiOnRIFUI): 43편 재생목록, 2022년 2월 마지막 업데이트(화면이 지금과 다를 수 있음)
- **Intune**
    - [Microsoft Intune Admin Center Tutorial - Full Walkthrough](https://www.youtube.com/watch?v=rEJdL7YWKq4): AzureCloudToday, 10분. 장치 등록·규정 준수·구성, 앱, 엔드포인트 보안, 보고서
    - [\#14 Microsoft Intune Admin Center Complete Walkthrough](https://www.youtube.com/watch?v=IFeGj8BZA3M): Labs Hands On, 9분. 포털 둘러보기
- **Azure 관리 (AZ-104 공식 시리즈, Microsoft Learn, 전 29편)**
    - [1편 Course Introduction](https://www.youtube.com/watch?v=6rs-oGmz3pk): 7분. 과정 소개
    - [4편 Describe the core architectural components of Azure](https://www.youtube.com/watch?v=9dZK_d-nZp8): 40분
    - [5편 Azure Policy initiatives](https://www.youtube.com/watch?v=XGL-8ZaBU4s), [6편 Azure RBAC](https://www.youtube.com/watch?v=uk8xwyudb1k)
    - [8편 Configure virtual networks](https://www.youtube.com/watch?v=PLwE82PNEpg), [9편 Network security groups](https://www.youtube.com/watch?v=6Gr17HqHfUw), [11편 Virtual Network peering](https://www.youtube.com/watch?v=gxvdN8hZRtQ)
    - [16편 Configure storage accounts](https://www.youtube.com/watch?v=NKmq1t41Zys), [20편 Introduction to Azure virtual machines](https://www.youtube.com/watch?v=mCMpIUGYI48), [21편 Configure virtual machine availability](https://www.youtube.com/watch?v=Sz6yhVDs4yY)
    - [27편 Introduction to Azure Monitor](https://www.youtube.com/watch?v=p7Kw1YJl2S4), [29편 Azure Monitor logs 분석](https://www.youtube.com/watch?v=Spf9SMfK000)
    - [AZ-104 Full Course - 12 Hours](https://www.youtube.com/watch?v=qXk8_0z_HsU): Certsqill, 11시간 49분. 모듈 구성은 거버넌스 0:27, 스토리지 1:56:11, 컴퓨팅 3:29:08, 네트워킹 5:31:32, 모니터링 7:15:25

</details>

> 확인 불가: SharePoint·Teams 영역의 영어 영상은 내용까지 확인한 것이 없습니다(시도: 후보 영상 자막 확인, 사유: 후보였던 풀코스 영상은 힌디어 강의이고 해당 내용이 자막에 나오지 않아 제외). 영상과 공식 문서가 다르면 공식 문서를 따르세요.

### 3. 공식 문서 출처

아래 Microsoft Learn 문서로 직접 확인한 내용:

- 하이브리드 인증 3방식 비교(3주차)
- Conditional Access 동작과 라이선스(4주차)
- 공동 책임 모델 매트릭스(0주차)
- Entra join과 hybrid join 권고(3주차)
- Entra role과 Azure RBAC 구분(2주차)
- Entra Connect 동기화 주기와 명령(3주차)

그 외 항목은 공식 문서의 용어를 기준으로 정리했으니 해당 주차에 Microsoft Learn에서 교차 확인하세요.

<details markdown="1">
<summary>공식 문서 출처 펼쳐 보기 (9건)</summary>

- [Choose the right authentication method for your Microsoft Entra hybrid identity solution](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- [What is Conditional Access?](https://learn.microsoft.com/entra/identity/conditional-access/overview)
- [Build a Conditional Access policy](https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-policies)
- [Analyze Conditional Access Policy Impact (report-only)](https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-report-only)
- [Shared responsibility in the cloud](https://learn.microsoft.com/azure/security/fundamentals/shared-responsibility)
- [Microsoft Entra joined vs. Hybrid Microsoft Entra joined in cloud-native endpoints](https://learn.microsoft.com/intune/solutions/cloud-native-endpoints/entra-join-types)
- [What is a device identity?](https://learn.microsoft.com/entra/identity/devices/overview)
- [Azure roles, Microsoft Entra roles, and classic subscription administrator roles](https://learn.microsoft.com/azure/role-based-access-control/rbac-and-directory-admin-roles)
- [Microsoft Entra Connect Sync: Scheduler](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-sync-feature-scheduler)

</details>
