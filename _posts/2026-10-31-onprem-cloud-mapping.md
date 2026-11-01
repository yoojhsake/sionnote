---
title: "[Study] 온프레미스 ↔ 클라우드 대응표와 옛 이름 ↔ 새 이름"
date: 2026-10-31 10:14:00 +0900
categories: [study]
phase: 부록
seq: 1
tags: [Study, Entra ID, Azure, Microsoft 365, 온프레미스, 이름 변경]
excerpt: "GPO는 Intune과 CA로, Domain Admins는 PIM으로. 온프레미스 구성요소의 클라우드 짝과 바뀐 이름"
---

GPO는 클라우드에서 무엇이 되고, Domain Admins 상시 권한은 어디로 갈까요? 온프레미스 구성요소 12가지의 클라우드 짝과 바뀐 제품 이름 15가지를 표 하나씩으로 보면, 옛 이름이 섞인 자료도 막힘없이 읽을 수 있습니다.

## 요약

- 온프레미스 구성요소와 딱 맞는 클라우드 짝은 드물어 달라지는 점까지 봐야 함
- 옛 이름이 섞인 자료는 바뀐 이름 표와 함께 찾아 읽으면 됨
- AzureAD와 MSOnline 모듈이 공지대로 실제 멈췄는지는 확인 불가임

12주 학습 로드맵의 부록입니다. 이전 글은 [모니터링과 통합 (12주차)]({{ "/study/azure-monitoring-onboarding/" | relative_url }}), 다음 글은 [용어 전집과 영상, 자료]({{ "/study/cloud-study-glossary/" | relative_url }})이고, 전체는 [전체 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에 있습니다.

---

## 전체 내용

### 1. 온프레미스 ↔ 클라우드 대응표

#### 신원, 정책, 권한

| 온프레미스 | 클라우드 | 전환할 때 달라지는 점 |
|---|---|---|
| AD DS | Entra ID | 계층(OU)이 없고 OAuth, OIDC, SAML 중심. 관리는 Graph |
| Azure AD Connect(이전 이름) | Entra Connect | 하이브리드 ID의 핵심. 인증 방식(PHS, PTA, Federation) 선택 |
| AD FS | Entra SSO, 앱 등록 | 페더레이션 서버 대신 클라우드 인증 |
| GPO | Intune 구성 프로필, Conditional Access | 도메인 가입 없이 적용. 접근 통제는 CA로 |
| AD CS | Intune Certificate Connector, Cloud PKI, Key Vault | 인증서 배포 경로와 수명주기 관리 방식이 다름 |
| Domain Admins 상시 권한 | PIM Eligible assignment | JIT 활성화와 승인, 기간 제한 |

#### 서비스와 인프라

| 온프레미스 | 클라우드 | 전환할 때 달라지는 점 |
|---|---|---|
| Exchange Server | Exchange Online | DAG와 DB 운영이 사라지고 정책 구성 중심 |
| 파일 서버 | SharePoint, OneDrive | 폴더 ACL에서 사이트와 공유 링크 모델로 |
| WSUS, MECM | Intune, Windows Autopatch | 클라우드 기반 업데이트 링 |
| 방화벽, VLAN | NSG, VNet, Azure Firewall | 장비 설정이 아니라 리소스 설정 |
| 이벤트 로그 수집 서버 | Log Analytics, Sentinel | 로그 수집과 분석이 서비스로 제공됨 |
| 서버 대수와 장비 구매 | VM, 구독, 종량제 | CapEx에서 OpEx로 |

Entra ID와 AD DS의 차이, 하이브리드 인증 방식, PIM은 IAM 시리즈의 [기초와 구조]({{ "/iam/what-is-entra-id/" | relative_url }}), [접근 제어]({{ "/iam/entra-id-access-control/" | relative_url }}), [하이브리드와 외부 사용자]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) 글에서 자세히 다룹니다.

### 2. 옛 이름 ↔ 새 이름

#### Entra ID 계열

| 옛 이름 | 현재 이름 |
|---|---|
| Azure Active Directory (Azure AD) | Microsoft Entra ID |
| Azure AD Connect | Microsoft Entra Connect |
| Azure AD Join, Hybrid Azure AD Join | Microsoft Entra join, hybrid join |
| Azure AD Premium P1, P2 | Microsoft Entra ID P1, P2 |
| Azure AD Domain Services | Microsoft Entra Domain Services |
| Azure AD Conditional Access | Microsoft Entra Conditional Access |
| Azure AD Privileged Identity Management | Microsoft Entra PIM |
| Azure AD Identity Protection | Microsoft Entra ID Protection |

#### 보안과 관리 도구

| 옛 이름 | 현재 이름 |
|---|---|
| Azure Security Center, Azure Defender | Microsoft Defender for Cloud |
| Azure Sentinel | Microsoft Sentinel |
| Microsoft 365 Defender | Microsoft Defender XDR |
| Azure Advanced Threat Protection | Microsoft Defender for Identity |
| Microsoft Endpoint Manager admin center | Microsoft Intune admin center |
| Azure Purview, Microsoft 365 compliance | Microsoft Purview |
| AzureAD, MSOnline PowerShell | Microsoft Graph PowerShell, Microsoft Entra PowerShell |

- AzureAD, MSOnline PowerShell 모듈은 이름만 바뀐 것이 아니라 지원이 끝난(deprecated) 모듈이라, 새 스크립트는 위 표의 대체 모듈로 씁니다.
    - MSOnline: 2025년 4월 초~5월 말 은퇴(작동 중지) 일정으로 공지됐습니다.
    - AzureAD: 2025년 3월 30일 이후 지원 종료, 은퇴는 2025년 7월 초로 공지됐습니다. 두 모듈이 공지대로 실제로 멈췄는지는 확인 불가입니다(Microsoft Learn의 Entra 새 소식 기록을 검색했지만 공지 일정만 있고 완료 기록은 찾지 못했습니다).
    - Microsoft Entra PowerShell은 AzureAD, AzureAD Preview 모듈과 98% 이상 호환되는 cmdlet을 제공합니다.

### 3. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: [Introduction to Microsoft Entra Connect V2](https://learn.microsoft.com/entra/identity/hybrid/connect/whatis-azure-ad-connect-v2): 옛 제품명 Azure AD Connect(V1은 2022-08-31 은퇴)
- 문서: [Archive for Microsoft Entra releases and announcements: January 2025](https://learn.microsoft.com/entra/fundamentals/whats-new-archive#january-2025): MSOnline 2025년 4월 초~5월 말 은퇴, AzureAD 2025-03-30 이후 미지원과 2025년 7월 초 은퇴, 대체 모듈 Microsoft Graph PowerShell SDK와 Microsoft Entra PowerShell
- 문서: [Upgrade from Azure AD PowerShell to Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/migration-steps?view=graph-powershell-1.0): Azure AD, Azure AD Preview, MSOnline 모듈 deprecated
- 문서: [Find Azure AD PowerShell and MSOnline cmdlet equivalents in Microsoft Entra PowerShell](https://learn.microsoft.com/powershell/entra-powershell/azuread-powershell-to-entra-powershell-mapping?view=entra-powershell): Microsoft Entra PowerShell은 98% 이상 호환

</details>
