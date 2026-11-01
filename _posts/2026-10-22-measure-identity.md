---
title: "[M365·Azure] 실측, Identity·Entra: 관리자, MFA, 조건부 액세스, 그룹·게스트 설정 (전체 기록)"
date: 2026-10-22 11:00:00 +0900
categories: [m365]
phase: 운영 설정 실측
seq: 2
tags: [M365·Azure, 실측, Entra, 조건부 액세스, MFA, 게스트, PIM, 전체 기록]
excerpt: "Entra 설정을 바꾸지 않고 22개 영역을 읽어 보니 위험 10건. 전역 관리자 2명 영구 활성, MFA 가능 20명 중 2명"
---

기본값 그대로인 Entra 테넌트는 얼마나 안전할까요? 설정을 하나도 바꾸지 않고 22개 영역을 읽어 정상·주의·위험·측정 불가로 판독하니 위험이 10건이었고, 전역 관리자 2명은 모두 영구 활성, MFA 가능 사용자는 20명 중 2명뿐이었습니다.

## 요약

- 위험 판독 대부분은 기본값을 그대로 둔 데서 나옴
- 정책 0개는 안전이 아니라 통제 없음이고 못 읽은 값은 측정 불가로 적어야 함
- 감사 로그에 작업 기록과 맞지 않는 변경 후보가 있어 1:1 대조가 남음

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. "개선 방안"은 권고일 뿐 이번에 실행하지 않았습니다.

---

## 전체 기록

### 1. 목표

측정은 2026-10-22(목)~10-23(금)에 읽기 전용으로 했고 저장, 적용 버튼은 누르지 않았습니다. 측정 방법과 판독 기준은 [측정 방법 글]({{ "/m365/measurement-method/" | relative_url }})에 있습니다.

### 2. 결과: 영역별 판독

읽은 값(조회)을 판독 결과별로 묶었습니다. 읽지 못한 항목은 7절에 있습니다.

#### 위험 (10건)

- 전역 관리자·PIM: 전역 관리자 2명, 모두 활성, 직접 할당, 범위 테넌트. 활성 할당 4건이 모두 영구, 적격 할당 0
- 비상(break-glass) 계정: 사용자 20명 중 없음
- MFA 등록: 20명 중 "다단계 인증 가능" 2명, 18명 불가
- 그룹 만료 정책: 그룹 수명 비어 있음, 적용 대상 "없음"
- 그룹 생성 권한: 사용자의 M365 그룹 생성 "예", 보안 그룹 "예"
- 그룹 명명 정책: 설정 없음
- 게스트 초대: "게스트와 비관리자를 포함해 조직 내 모든 사용자가 초대 가능"(가장 포괄적)
- 관리자 동의 워크플로: 꺼짐, 검토자 0
- 액세스 검토: 정의 0개
- 진단 설정: 정의된 설정 없음

#### 주의 (5건)

- 조건부 액세스: 정책 0개(목록 비어 있고 템플릿 안내만), 보안 기본값 사용 중. Graph 조회는 HTTP 403
- 사용자 동의: "Microsoft에서 동의 설정 관리(권장)"
- 테넌트 간 액세스: 기본 설정(인바운드·아웃바운드 B2B 허용 기본값)
- 권장 사항(Entra): 7건(모두 보안), ID 보안 점수 60.40%
- 게스트 디렉터리 접근: 속성과 멤버 자격이 제한됨(기본값). 정상~주의

#### 정상, 해당 없음 (5건)

- 도메인: 1개, 사용 가능, 미검증 0 (정상)
- 동적 그룹: 그룹 11개 중 동적 2개, 일시 중지 0 (정상)
- 앱 등록: 0개 (해당 없음, 정상)
- Guest: 20명 전원 Member, Guest 0 (해당 없음, 정상)
- 하이브리드 동기화: "사용 안 함, 동기화 실행된 적 없음"(클라우드 전용). 해당 없음

#### 측정 불가 (2건)

- 90일 미로그인: 사용자 목록에 "마지막 로그인" 열이 없고 열 편집 메뉴를 열지 못함
- 소유자 없는 Team: 목록에 소유자 수 열이 없음

### 3. 측정하며 배운 점

기본값에서 나온 위험은 그룹 생성, 게스트 초대, 앱 동의, 만료 없음입니다. 비상 계정 생성과 조건부 액세스 전환은 보안 설정과 계정 변경이라 하지 않았습니다.

### 4. 영역별 측정 과정

<details markdown="1">
<summary>자세히 보기 (그림 7장)</summary>

#### 관리자 계정과 비상 계정

- **GUI 경로**: Entra > 역할 및 관리자 > 전역 관리자 > 활성 할당 / 적격 할당 탭, 사용자 목록. PIM의 활성 역할 목록에서도 읽었습니다.
- 조회: 전역 관리자 2명 모두 "활성, 직접, 범위 테넌트", 적격 할당 결과 없음.
    - PIM의 활성 할당은 4건(전역 관리자 2명, Teams 관리자 1명 포함)이 모두 멤버 자격 "직접", 상태 "할당됨", 종료 시간 "영구"이고 적격 할당은 0건입니다.
    - 사용자 20명 중 비상 계정 이름 없음.

업무용 계정이 항상 최고 권한을 쥐고 있고, 막히면 되돌릴 계정이 없습니다. 문서도 전역 관리자는 최소화하고 비상 계정을 두라고 권합니다.

개선 방안(미실행)은 클라우드 전용 비상 계정 2개를 만들어 조건부 액세스 정책에서 제외하고 암호는 분리 보관하는 것입니다. 업무 계정은 적격 할당(PIM)으로 전환합니다. 비상 계정 생성은 7절에 남겼습니다.

근거: [Entra 역할 개념](https://learn.microsoft.com/entra/identity/role-based-access-control/concept-understand-roles), [비상 접근 계정](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)

![전역 관리자 활성 할당 화면]({{ "/assets/images/2026/10/m07-1-ga-active.png" | relative_url }})
*그림 1. Entra > 역할 및 관리자 > 전역 관리자 > 활성 할당 탭. 전역 관리자 아래 2명이 "사용자 / 직접"으로 보이고 범위는 테넌트입니다(이름, 계정, 범위는 가렸습니다). 적격 할당 탭은 결과가 없었습니다.*

![PIM 활성 역할 목록]({{ "/assets/images/2026/10/m11-4-pim-active.png" | relative_url }})
*그림 2. Entra PIM의 활성 역할 목록. Teams 관리자, 전역 관리자, 청구 관리자 아래 항목이 모두 멤버 자격 "직접", 상태 "할당됨", 종료 시간 "영구"입니다. 이름, 계정, 범위는 가렸습니다.*

#### MFA 등록 현황

- **GUI 경로**: Entra ID > 인증 방법 > 활동 > 사용자 등록 세부 정보(영문 문서 표기: Entra ID > Authentication methods > Activity. 포털 메뉴 이름은 개편으로 달라질 수 있음)
- 조회: "다단계 인증 가능" 2명 / 20명(90%가 미등록).

보안 기본값이 켜져 있으므로 미등록 사용자는 **다음 로그인 때 등록을 요구받습니다**(문서). "아직 등록 안 한 것"이지 "보호가 꺼진 것"은 아닙니다. 다만 등록 전까지는 실제 보호가 없다고 봐야 합니다.

실제 로그인 프롬프트 동작은 확인 불가입니다.

- 시도: 로그인 프롬프트 확인 / 막힌 이유: 본인 계정의 인증 정보를 입력해야 하는 시험이라 하지 않음 / 다음 방법: 브라우저 InPrivate 창에서 로그인해 프롬프트 확인.
- 근거: [Security defaults](https://learn.microsoft.com/entra/fundamentals/security-defaults)

![인증 방법 사용자 등록 세부 정보]({{ "/assets/images/2026/10/m07-5-mfa-registration.png" | relative_url }})
*그림 3. Entra > 인증 방법 > 사용자 등록 세부 정보. "다단계 인증 가능" 열이 대부분 "불가능"이고 "사용 가능"은 20명 중 2명입니다. 사용자 계정, 이름 열과 테넌트 이름은 가렸습니다.*

#### 조건부 액세스와 보안 기본값

- **GUI 경로**: Entra > 보호 > 조건부 액세스 > 정책
- 조회(GUI): 정책 목록이 비어 있고 예시 템플릿 안내만 표시됩니다. 정책 0건은 GUI에서 두 번 확인했습니다.
    - 정책이 없으므로 "제외 대상 설정"은 해당 없음입니다.
- 조회(PowerShell): 같은 목록을 PowerShell로 조회하면 **HTTP 403**이 났습니다. 원인 후보는 두 가지입니다.
    - ① 사용자 역할 부족
    - ② `Invoke-AzRestMethod`가 쓰는 Azure PowerShell 앱 토큰에 `Policy.Read.All` 범위가 없음(역할이 충분해도 403 가능)

```powershell
$ca = Invoke-AzRestMethod -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
"CA|http=$($ca.StatusCode)"      # CA|http=403
```

정책이 0개라 조건 기반 통제가 없습니다. 보안 기본값과 조건부 액세스는 함께 쓸 수 없고, 조건부 액세스를 쓰려면 보안 기본값을 꺼야 합니다(문서).

해결 방안(미실행): 보안 기본값을 끄고 조건부 액세스로 전환하는 것은 **보안 설정 변경**이라 관리자와 보안팀이 결정할 사항입니다. 비상 계정을 먼저 만든 뒤, 모든 사용자에게 MFA를 요구하는 정책부터 "보고 전용"으로 시험합니다.

두 후보 중 어느 쪽인지, Graph 조회에 필요한 최소 읽기 역할이 무엇인지는 확인 불가입니다.

- 시도: Graph 정책 목록 조회(HTTP 403) / 막힌 이유: 역할을 바꿔 시험하는 것은 권한 변경이라 하지 않음 / 다음 방법: 읽기 역할 또는 토큰 범위를 확보한 뒤 다시 조회.

![조건부 액세스 정책 화면]({{ "/assets/images/2026/10/m07-3-ca-policies.png" | relative_url }})
*그림 4. Entra > 조건부 액세스 > 정책. 목록이 비어 있고 "조건부 액세스란 무엇인가요?" 예시 안내만 표시됩니다(정책 0개). 계정 표시는 가렸습니다.*

#### 그룹 만료, 생성, 명명 정책

- **GUI 경로**: Entra > 그룹 > 만료 / 일반(그룹 설정) / 명명 정책
- 조회: 만료 정책 없음(두 번 확인, Teams 관리 센터의 팀 목록에서도 만료일 열이 모두 "-"), 사용자 그룹 생성 허용, 명명 정책 없음.

누구나 그룹(=Team)을 만들 수 있고 만료나 이름 규칙이 없으면, 주인 없는 그룹과 이름이 제각각인 그룹이 쌓입니다. 문서도 기본값은 모든 사용자의 그룹 생성을 허용한다고 설명합니다.

개선 방안(미실행)은 아래 세 가지입니다. 명명 정책에는 Entra ID P1 라이선스가 필요하며 이 테넌트는 P2 포함입니다.

- 만료 정책(활동이 있으면 자동 갱신, 소유자에게 알림, 갱신 안 하면 삭제 후 30일 복구)
- 이름 접두어, 차단 단어
- 그룹 생성 권한 제한

근거: [그룹 만료](https://learn.microsoft.com/entra/identity/users/groups-lifecycle), [명명 정책](https://learn.microsoft.com/entra/identity/users/groups-naming-policy), [M365 그룹 관리 작업](https://learn.microsoft.com/troubleshoot/exchange/groups-and-distribution-lists/o365-group-tasks)

![그룹 만료 설정 화면]({{ "/assets/images/2026/10/m07-4-group-expiration.png" | relative_url }})
*그림 5. Entra > 그룹 > 만료. "그룹 수명(일)" 값이 비어 있고 "다음 Microsoft 365 그룹에 만료 적용"이 "없음"으로 선택되어 있어 만료 정책이 설정되어 있지 않습니다. 이 화면에서 아무 값도 저장하지 않았습니다. 계정, 테넌트 이름은 가렸습니다.*

#### 게스트와 외부 공동 작업 설정

- **GUI 경로**: Entra > External Identities > 외부 협업 설정
- 조회: 게스트 초대 = 모든 사용자 허용(가장 포괄적), 게스트 접근 = 디렉터리 개체 속성·멤버 자격 제한. 테넌트 간 액세스는 기본값, 현재 Guest는 0명.

협업 제한 화면까지 읽었습니다. "모든 도메인에 초대를 보낼 수 있도록 허용(가장 포괄적)"이 선택되어 있어 허용·차단 도메인 목록은 쓰지 않는 상태입니다. 게스트 셀프 서비스 등록은 "아니요", 외부 사용자 나가기 허용은 "예"입니다.

![Entra 외부 협업 설정 화면]({{ "/assets/images/2026/10/m13-ext-collab.png" | relative_url }})
*그림 6. Entra > External Identities > 외부 협업 설정(아래쪽). 게스트 초대 제한, 셀프 서비스 등록, 나가기 설정, 협업 제한 사항 모두 값만 읽고 바꾸지 않았습니다.*

문서에 따르면 기본값은 "게스트를 포함한 조직의 모든 사용자가 초대 가능"입니다. 이러면 누가 초대했는지 책임이 흩어집니다. 권장은 관리자와 Guest Inviter 역할만 초대하게 하는 것입니다.

개선 방안(미실행): 초대 권한을 Guest Inviter, User Administrator로 제한하고 필요한 도메인만 허용 목록으로 관리합니다. 값을 바꾸더라도 Teams, SharePoint 설정은 Entra보다 느슨해질 수 없습니다(Entra 설정이 우선).

근거: [외부 협업 설정](https://learn.microsoft.com/entra/external-id/external-collaboration-settings-configure), [게스트 권한 제한](https://learn.microsoft.com/entra/identity/users/users-restrict-guest-permissions), [Governed collaboration](https://learn.microsoft.com/entra/architecture/5-secure-access-b2b), [Teams·SharePoint 외부 접근](https://learn.microsoft.com/entra/architecture/9-secure-access-teams-sharepoint)

#### 앱 동의

- **GUI 경로**: Entra > 엔터프라이즈 앱 > 동의 및 권한 > 사용자 동의 설정 / 관리자 동의 설정
- 조회: 사용자 동의 = "Microsoft에서 동의 설정 관리(권장)", 관리자 동의 요청 워크플로 = 아니요, 검토자 0, 만료 30일 설정값.

워크플로가 꺼져 있으면 승인할 수 없는 앱을 만난 사용자는 막히고, 관리자는 요청을 알 수 없습니다.

개선 방안(미실행): 워크플로를 켜고 검토자를 지정합니다(켜려면 전역 관리자 필요, 적용까지 최대 1시간). 검토자는 요청을 볼 수 있지만 승인은 필요한 권한이 있는 역할만 할 수 있습니다.

근거: [사용자 동의 설정](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-user-consent), [관리자 동의 워크플로](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-admin-consent-workflow)

#### 액세스 검토와 진단 설정

조회해 보니 액세스 검토 정의 0(두 번 확인), 진단 설정 "정의된 설정 없음"이었습니다. Guest 거버넌스 화면은 구독 연결이 필요하다는 안내가 나왔습니다.

권한을 정기적으로 점검하는 장치도, 로그를 보관하고 내보내는 장치도 없는 상태입니다. Entra 감사·로그인 로그는 P1·P2 테넌트에서 30일(Free는 7일)만 보관되므로, 그보다 오래 두려면 진단 설정으로 내보내야 합니다(문서: [Microsoft Entra data retention](https://learn.microsoft.com/entra/identity/monitoring-health/reference-reports-data-retention)).

조건부 액세스 Workbook은 Log Analytics 작업 영역이 필요합니다. 리소스 공급자 Microsoft.OperationalInsights와 Microsoft.Insights는 둘 다 Registered이지만(조회, 비용 없음), 작업 영역 생성은 비용 항목이라 만들지 않았습니다. 그래서 Workbook 값은 **확인 불가**입니다(아래 7절).

![액세스 검토 화면]({{ "/assets/images/2026/10/m07-2-access-review.png" | relative_url }})
*그림 7. Entra > Identity Governance > 액세스 검토. 목록에 "표시할 액세스 검토가 없음"이 나오고, 위쪽 안내는 Guest 거버넌스 기능에 Azure 구독 연결이 필요하다는 내용입니다. 계정 표시는 가렸습니다.*

#### 권장 사항과 ID 보안 점수

권장 사항은 7건(보안 7, 모범 사례 0), **ID 보안 점수 60.40%**였습니다(조회). 7건은 다음과 같습니다.

- 조건부 액세스의 내부 위험 조건(P2)
- 신뢰할 수 없는 앱 동의 허용 안 함
- 둘 이상의 전역 관리자 지정
- 하이브리드 암호 해시 동기화
- 암호 만료 안 함
- 최소 권한 관리자 역할
- 셀프 서비스 암호 재설정

점수는 위험 확률이 아니라 "권장 기능을 얼마나 쓰고 있는가"의 지표입니다. 문서도 점수 자체보다 중요도가 높은 항목부터 처리하라고 안내합니다. 앱이 0개라 "사용하지 않는 앱·자격 증명 제거" 권장 사항은 나오지 않았습니다.

근거: [Identity Secure Score](https://learn.microsoft.com/entra/identity/monitoring-health/concept-identity-secure-score), [Entra 권장 사항](https://learn.microsoft.com/entra/identity/monitoring-health/overview-recommendations)

#### 감사 로그로 변경 대조

최근 24시간 Entra 감사 로그에는 변경 이벤트가 여럿 있었습니다(조회).

- Azure RBAC 상승 액세스 2건(09:57 상승, 11:02 해제)
- 사용자 업데이트(부서 변경 2건)
- 그룹 업데이트 1건(13:03)
- 서비스 사용자 추가 4건(포털 첫 접속 때 자동 생성되는 것으로 추정)

Elevate access 켬·끔 기록은 Entra 감사 로그와 일치했습니다. 10/22는 09:57 켬, 11:02:59 끔이고, 10/23은 09:46:43 켬, 09:50:23 끔, 09:56:36 켬, 16:01:10 끔입니다(조회). 시험 그룹 DG-Practice-01은 관리자 계정이 2026-10-14 11:14에 생성한 것이 감사 로그로 확인됩니다.

판독은 주의입니다. 이 중 **제 변경 이력과 맞지 않는 후보**가 있습니다(13:03 그룹 업데이트, 서비스 사용자 추가 4건). 1:1 대조에는 작업 기록 확인이 필요하고, 서비스 사용자 추가가 자동 생성이라는 것은 추정일 뿐 확인된 사실이 아닙니다.

기록과 로그가 맞지 않으면 누가 했는지 모르는 변경이 됩니다. Elevate를 켜고 끈 과정은 [관리 그룹 설정 403 트러블슈팅]({{ "/m365/troubleshooting/mg-settings-403-elevate-access/" | relative_url }})에 있습니다.

</details>

### 5. 작업 중 막힌 곳

Exchange PowerShell 장치 코드 로그인이 AADSTS530035로 차단돼, 보안 기본값은 두고 관리 센터 화면으로 읽었습니다. [AADSTS530035 트러블슈팅]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})

### 6. 남은 일

- 감사 로그의 13:03 그룹 업데이트와 서비스 사용자 추가 4건을 작업 기록과 1:1로 대조합니다(위 '감사 로그로 변경 대조').
- 조건부 액세스 전환(미실행 권고)은 관리자와 보안팀이 결정할 사항입니다.

### 7. 확인 불가로 남은 것

<details markdown="1">
<summary>확인 불가 항목 펼쳐 보기 (7건)</summary>

- 90일 미로그인 사용자
    - 시도 방법: 사용자 목록 기본 열 확인, 열 편집 메뉴 열기
    - 막힌 이유: 기본 열에 "마지막 로그인"이 없고 열 편집 메뉴가 열리지 않음
    - 다음 방법: 사용자 > 열 편집에서 마지막 로그인 추가 후 재측정
- 소유자 없는 Team
    - 시도 방법: 팀 목록, 활성 팀 화면 확인
    - 막힌 이유: 소유자 수 열이 없음
    - 다음 방법: 팀별 상세 또는 Graph로 조회
- 조건부 액세스 Graph 조회
    - 시도 방법: `Invoke-AzRestMethod`로 정책 목록 조회
    - 막힌 이유: HTTP 403. 역할 부족인지 토큰 범위 부족인지 구분 못 함. 역할이나 범위를 바꿔 시험하는 것은 설정 변경이라 하지 않음
    - 다음 방법: 읽기 역할 또는 토큰 범위 확보 후 재조회(GUI로는 정책 0건 확인 완료)
- 조건부 액세스 Workbook
    - 시도 방법: (작업 영역이 필요)
    - 막힌 이유: Log Analytics 작업 영역이 없고, 생성은 비용 항목이라 하지 않음
    - 다음 방법: 운영 환경에서 과금 조건을 확인한 뒤 작업 영역 생성 후 측정
- 비상(break-glass) 계정
    - 시도 방법: 사용자 목록 확인(없음)
    - 막힌 이유: 계정 생성은 하지 않음
    - 다음 방법: 비상 계정을 만드는 작업을 할 때 생성(시험 후 삭제)
- MFA 실제 로그인 동작
    - 시도 방법: 로그인 프롬프트 확인
    - 막힌 이유: 본인 계정의 인증 정보를 입력해야 하는 시험이라 하지 않음
    - 다음 방법: 브라우저 InPrivate 창에서 로그인해 프롬프트 확인
- 하이브리드 항목 전반
    - 시도 방법: 동기화 상태 화면 확인("사용 안 함")
    - 막힌 이유: 클라우드 전용 테넌트라 대상이 없음
    - 다음 방법: 하이브리드 환경에서 측정

</details>

### 8. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (8건)</summary>

- 문서: 전역 관리자 최소화, 역할 개념: [Entra 역할 개념](https://learn.microsoft.com/entra/identity/role-based-access-control/concept-understand-roles)
- 문서: 비상 접근 계정: [비상 접근 계정](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)
- 문서: 보안 기본값과 MFA 등록 요구: [Security defaults](https://learn.microsoft.com/entra/fundamentals/security-defaults)
- 문서: 그룹 만료, 명명 정책, 그룹 관리: [그룹 만료](https://learn.microsoft.com/entra/identity/users/groups-lifecycle), [명명 정책](https://learn.microsoft.com/entra/identity/users/groups-naming-policy), [M365 그룹 관리 작업](https://learn.microsoft.com/troubleshoot/exchange/groups-and-distribution-lists/o365-group-tasks)
- 문서: 외부 협업·게스트 권한: [외부 협업 설정](https://learn.microsoft.com/entra/external-id/external-collaboration-settings-configure), [게스트 권한 제한](https://learn.microsoft.com/entra/identity/users/users-restrict-guest-permissions), [Governed collaboration](https://learn.microsoft.com/entra/architecture/5-secure-access-b2b), [Teams·SharePoint 외부 접근](https://learn.microsoft.com/entra/architecture/9-secure-access-teams-sharepoint)
- 문서: 앱 동의: [사용자 동의 설정](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-user-consent), [관리자 동의 워크플로](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-admin-consent-workflow)
- 문서: ID 보안 점수·권장 사항: [Identity Secure Score](https://learn.microsoft.com/entra/identity/monitoring-health/concept-identity-secure-score), [Entra 권장 사항](https://learn.microsoft.com/entra/identity/monitoring-health/overview-recommendations)
- 조회: 전역 관리자, PIM, MFA, 조건부 액세스, 그룹, 게스트, 동의, 액세스 검토, 감사 로그. 위 각 절의 GUI 경로와 그림

</details>
