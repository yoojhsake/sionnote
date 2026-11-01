---
title: "[Study] Intune: 디바이스 관리와 GPO 전환"
date: 2026-10-31 10:09:00 +0900
categories: [study]
phase: 2단계 Microsoft 365
seq: 4
tags: [Study, M365, Intune, Autopilot, Compliance policy, Settings catalog, GPO, Cloud PKI]
excerpt: "디바이스 상태가 접근 통제의 입력값이 됩니다. GPO 전환, Autopilot, Compliance와 CA, SCEP·PKCS 배포까지"
---

GPO가 하던 구성을 클라우드에서는 Intune이 맡고, Intune이 판정한 디바이스 상태가 Conditional Access의 입력값이 됩니다. 이번 주를 마치면 GPO를 Settings catalog로 옮기는 경로와 인증서(SCEP·PKCS) 배포 방식을 설명할 수 있습니다.

## 요약

- Intune은 Windows, macOS, iOS, Android 디바이스를 클라우드에서 관리하는 서비스. GPO가 하던 구성은 Settings catalog와 Administrative templates, 접근 통제는 Compliance policy와 Conditional Access 조합으로 대체
- 가장 중요한 연결점은 Intune이 디바이스를 compliant로 표시하면 Conditional Access가 "규정 준수 디바이스 요구"로 접근을 통제한다는 것
- 기존 GPO는 Group Policy analytics로 Intune 지원 여부를 분석한 뒤 Settings catalog로 옮김
- 신규 PC는 Windows Autopilot으로 Entra join과 Intune enrollment를 한 번에
- 인증서는 SCEP 또는 PKCS 프로필로 배포, 온프레미스 AD CS와는 Intune Certificate Connector(및 NDES)로 연계

12주 학습 로드맵의 8주차입니다.
이전 글: [7주차 SharePoint·OneDrive·Teams]({{ "/study/sharepoint-onedrive-teams-structure/" | relative_url }}), 다음 글: [9주차 Azure 컴퓨팅·스토리지]({{ "/study/azure-compute-storage/" | relative_url }}), [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

Microsoft Intune, MDM, MAM, Enrollment, Windows Autopilot, Compliance policy, Configuration profile, Settings catalog, Administrative templates, Group Policy analytics, App protection policy, Win32 app, Update ring, Windows Autopatch, Co-management, Tenant attach, Device filter, Remediations, Intune Certificate Connector, SCEP·PKCS, Cloud PKI

### 2. 개념 설명

MDM은 디바이스 전체를 등록해 관리하고, MAM은 디바이스는 건드리지 않고 앱 단위로 데이터를 보호합니다(BYOD에서 자주 씁니다).

Enrollment는 Windows의 경우 Entra join과 함께 자동 등록되는 것이 일반적이고, 신규 디바이스 프로비저닝에는 Windows Autopilot을 씁니다. Autopilot은 사용자 주도(user-driven), self-deploying, pre-provisioning 같은 방식이 있고, 최근에는 device preparation 방식도 추가되었습니다.

GPO 전환에서 Settings catalog는 설정 항목을 검색해서 구성하는 방식이고, Administrative templates는 ADMX 기반 설정입니다.

- 기존 GPO는 GPMC에서 XML 파일로 내보낸 뒤(Save report), Intune의 **Group Policy analytics**로 가져와(Import) Intune에서 지원되는 설정인지 분석합니다.
- 문서: 가져온 GPO는 Settings catalog 정책으로 옮길 수 있고, GPO 하나의 XML은 4 MB보다 작아야 합니다([Group Policy analytics로 GPO 가져오기·분석](https://learn.microsoft.com/intune/device-configuration/import-group-policy-analytics#export-a-gpo-as-an-xml-file)).
Compliance policy와 Conditional Access는 이렇게 이어집니다. Intune이 디바이스를 "규정 준수(compliant)"로 표시하면 Conditional Access가 "규정 준수 디바이스 요구"로 접근을 통제합니다. 두 서비스가 연결되는 **가장 중요한 지점**입니다. 조건부 액세스 자체는 [4주차]({{ "/study/auth-security-mfa-ca-pim/" | relative_url }})와 [IAM 접근 제어 글]({{ "/iam/entra-id-access-control/" | relative_url }})에서 다룹니다.
업데이트는 Update ring과 Windows Autopatch가 WSUS와 MECM의 패치 배포를 대체하는 방향입니다.

Hybrid joined 디바이스는 GPO와 Intune을 같이 쓸 수 있지만, 둘을 섞으면 관리 부담이 늘어납니다. Co-management는 Intune과 Configuration Manager를 함께 쓰는 구성이고, 이 구성이면 Conditional Access 같은 Entra 기능을 일부 쓸 수 있습니다.

PKI 연계에서는 인증서를 Intune의 SCEP 또는 PKCS 프로필로 배포합니다.

- 온프레미스 AD CS와는 Intune Certificate Connector(및 NDES)로 연계합니다.
    - 클라우드 PKI가 필요하면 Microsoft Cloud PKI가 있습니다. Intune Plan 1·Plan 2 외에 추가 구독이 필요한 기능입니다.
    - 문서: 2026년 7월부터 Intune Suite 기능이 Microsoft 365 등급별로 나뉘어, Microsoft 365 E5·E7에 Cloud PKI가 포함됩니다. 그 밖의 플랜은 Intune Suite를 별도 구독으로 삽니다([Intune 계획 가이드: 비용과 라이선스](https://learn.microsoft.com/intune/fundamentals/planning-guide#step-3---determine-costs-and-licensing), [Cloud PKI 개요](https://learn.microsoft.com/intune/cloud-pki/#prerequisites)).
    - PKI 경험이 있다면 가장 자신 있게 설명할 수 있는 영역입니다.

### 3. 온프레미스로 번역하면

| Intune | 온프레미스 | 비고 |
|---|---|---|
| Configuration profile (Settings catalog) | GPO | 도메인 가입 없이 적용 |
| Compliance policy | 컴플라이언스 점검 스크립트·NAC | 결과가 Conditional Access와 연동 |
| Windows Autopilot | OSD·이미징 | 이미지 대신 클라우드 프로비저닝 |
| Update ring · Autopatch | WSUS · MECM 패치 | 클라우드 기반 배포 |
| Remediations | 컴플라이언스 설정(DCM) 스크립트 | 탐지 + 교정 스크립트 |
| Certificate Connector (SCEP·PKCS) | AD CS 자동 등록(autoenrollment) | 인증서 배포 경로가 다름 |

### 4. 실습 (GUI 우선)

1. Intune 관리 센터(intune.microsoft.com) > 디바이스(Devices) > 개요에서 등록된 디바이스 수와 규정 준수 현황을 확인합니다.
2. 디바이스 > 구성(Configuration)에서 프로필 유형(Settings catalog, Administrative templates)을 확인합니다. 새 프로필은 만들더라도 할당하지 않으면 영향이 없습니다.
3. 디바이스 > 규정 준수(Compliance)에서 정책 항목을 읽고 Conditional Access와 연결되는 지점을 찾아봅니다.
4. 테넌트 관리(Tenant administration) 화면에서 커넥터와 토큰(Connectors and tokens) 목록을 봅니다.

### 5. 전문가처럼 말하기

> "Intune의 compliance policy 결과가 Conditional Access의 'require compliant device'로 이어지기 때문에, 디바이스 상태가 접근 통제의 입력값이 됩니다."
>
> "신규 PC는 Autopilot으로 Entra join과 Intune enrollment를 한 번에 하고, GPO는 Group Policy analytics로 Intune 지원 여부를 분석한 뒤 Settings catalog로 옮깁니다."

### 6. 자가 점검

- MDM과 MAM의 차이를 말할 수 있다.
- Compliance policy와 Conditional Access가 연결되는 방식을 설명할 수 있다.
- GPO를 Intune으로 옮길 때 쓰는 도구를 말할 수 있다.
- Hybrid joined 디바이스에서 GPO와 Intune을 같이 쓸 때의 부담을 말할 수 있다.
- 인증서를 Intune으로 배포하는 두 가지 프로필 유형을 말할 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (5문항)</summary>

- MDM과 MAM: MDM은 디바이스 전체를 등록해 관리하고, MAM은 디바이스는 건드리지 않고 앱 단위로 데이터를 보호합니다.
- Compliance → CA: Intune이 디바이스를 compliant로 표시하면, Conditional Access의 "require compliant device"가 그 결과로 접근을 통제합니다.
- GPO 전환 도구: GPMC에서 XML로 내보낸 GPO를 Group Policy analytics로 가져와 Intune 지원 여부를 분석하고, Settings catalog(또는 ADMX 기반 Administrative templates)로 옮깁니다.
- Hybrid joined 부담: GPO와 Intune을 같이 쓸 수는 있지만, 둘을 섞으면 관리 부담이 늘어납니다.
- 인증서 프로필: SCEP와 PKCS입니다.

</details>

### 7. 영상·자료 (한글 우선)

- 한글: [\[MS Intune 기초편\] 사용자관리 - 인튠이란?](https://www.youtube.com/watch?v=7_dRLhnPwD0), [\[MS Intune 기초편\] 사용자관리 - 인튠 계정 암호 변경](https://www.youtube.com/watch?v=Kp5N_coWcfs), [교육용 인튠 튜토리얼 (Intune for Education)](https://www.youtube.com/watch?v=QunVzLs4ulE)
    - 세 영상 모두 교육청이나 교육용 환경에서 만든 영상이라 학교 예시가 섞여 있습니다.
    - 정의와 용어 정리 같은 기초 개념 용도로는 한글 자료로 쓸 만합니다.
- 영문 보완: [Microsoft Intune Admin Center Tutorial - Full Walkthrough](https://www.youtube.com/watch?v=rEJdL7YWKq4), [\#14 Microsoft Intune Admin Center Complete Walkthrough](https://www.youtube.com/watch?v=IFeGj8BZA3M)
