---
title: "[M365·Azure] 실측: SharePoint, OneDrive, M365 관리 센터의 공유, 보존, 메시지 센터, 서비스 상태 (전체 기록)"
date: 2026-10-22 12:30:00 +0900
categories: [m365]
phase: 운영 설정 실측
seq: 4
tags: [M365·Azure, 실측, SharePoint, OneDrive, 메시지 센터, 서비스 상태, 전체 기록]
excerpt: "설정을 바꾸지 않고 읽어 보니 외부 공유 슬라이더는 둘 다 \"누구나\", 메시지 센터는 기한 경과 16건이었다"
---

SharePoint와 OneDrive, M365 관리 센터의 공유, 보존, 메시지 센터, 서비스 상태 설정은 지금 어떤 상태일까요? 설정을 바꾸지 않고 읽기만 해 판독한 실측에서, 외부 공유 슬라이더 두 개가 모두 "누구나(Anyone)"였고 메시지 센터에는 조치 기한이 지난 공지가 16건 있었습니다.

## 요약

- 기본 링크가 로그인 없이 편집되는 링크라 실수로 넓게 공유되기 쉬움
- 공유는 최대치와 기본 링크와 만료를 함께 보고 공지 검토 담당을 정해야 함
- DAG 보고서와 Restricted SharePoint Search 현재 값은 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 사이트 주소도 게시하지 않았습니다. 개선 방안은 권고이며 **이번에 실행하지 않았습니다.**

---

## 전체 기록

### 1. 측정 범위와 방법

SharePoint 관리 센터와 M365 관리 센터를 2026-10-22(목)~10-23(금)에 읽기 전용으로 측정했습니다. 방법과 판독 기준은 [측정 방법 글]({{ "/m365/measurement-method/" | relative_url }})에 있습니다.

### 2. 판독 결과

| 판독 | 읽은 값(조회) |
|---|---|
| 위험 | 외부 공유 SharePoint·OneDrive 모두 Anyone, Anyone 링크 만료 미설정, 기본 링크 "링크가 있는 모든 사용자"·편집, 메시지 센터 기한 경과 16건, 서비스 상태 이메일 알림 미설정(활성 문제 9건) |
| 주의 | 사이트 생성 승인 없음·시간대 UTC-08:00, 퇴사자 OneDrive 보존 30일, 동기화 제한 없음, Customer Lockbox 승인 해제 |
| 정상 | 저장소 1.24 TB 중 24 MB 사용, 삭제된 사이트 0, 표준 릴리스, 소유자 없는 에이전트 0 |
| 참고·해당 없음 | 서비스 요청 0건, 에이전트·플러그인 모두 허용, Copilot 라이선스 없음, Intune 장치 0 |
| 측정 불가 | DAG 보고서, Restricted SharePoint Search, 사용 현황 보고서, M365 Apps 관리 센터 |

### 3. 운영 권고

1. 공유 수준을 "새 게스트와 기존 게스트"로 낮추거나 Anyone 링크에 만료일과 "보기" 권한을 둡니다. 기본 링크는 "특정 사용자"로 바꿉니다.
2. 메시지 센터는 담당자가 주 1회 검토하고 Planner 작업으로 추적합니다.
3. 서비스 상태 이메일 알림을 운영 공용 사서함과 담당자 1명으로 설정합니다.
4. 퇴사자 OneDrive 보존 기간을 업무 기준에 맞게 늘리고(30~3650일) 동기화 기기를 한정합니다.

### 4. 영역별 상세

#### 외부 공유 수준과 기본 링크

<details markdown="1">
<summary>값과 캡처 보기 (그림 1장)</summary>

- GUI 경로: SharePoint 관리 센터 > 정책 > 공유

Anyone 링크 만료는 체크 해제였고, Anyone 링크 권한은 파일 "보기 및 편집", 폴더 "보기, 편집 및 업로드"였습니다. 사용자는 보통 기본값을 그대로 쓰기 때문에 기본 링크가 가장 위험합니다. 슬라이더는 조직 최대치이고, 사이트별로 더 좁힐 수는 있지만 더 넓힐 수는 없습니다(문서).

권고 1의 세부: Anyone 링크 만료일은 예를 들어 수 주로 둡니다. 최대치가 Anyone이어도 기본 링크가 "특정 사용자"면 실수가 줄어듭니다. 민감 사이트는 사이트별로 더 엄격하게 두고, 민감도 레이블에 기본 공유 링크 동작을 묶는 방법도 있습니다.

기본 링크 유형을 바꾸면 이미 만든 링크에 영향이 있는지는 관련 문서에서 명시한 문장을 찾지 못해 확인 불가입니다. 이미 만든 링크 점검도 링크 목록을 측정하지 않았으므로 확인 불가입니다(두 항목 모두 5절).

근거: [외부 공유 켜기·끄기](https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off), [공동 작업 옵션](https://learn.microsoft.com/sharepoint/collaboration-options), [기본 공유 링크 변경](https://learn.microsoft.com/sharepoint/change-default-sharing-link), [사이트별 외부 공유](https://learn.microsoft.com/sharepoint/change-external-sharing-site), [민감도 레이블의 기본 공유 링크](https://learn.microsoft.com/purview/sensitivity-labels-default-sharing-link)

![SharePoint 관리 센터 공유 화면]({{ "/assets/images/2026/10/m09-1-spo-sharing.png" | relative_url }})
*그림 1. SharePoint 관리 센터 > 정책 > 공유. SharePoint와 OneDrive 두 슬라이더가 모두 맨 위 "누구나(Anyone)"에 있고, 기본 링크 유형은 "링크가 있는 모든 사용자", 권한은 "편집"이 선택되어 있습니다(값만 읽고 저장하지 않음).*

</details>

#### 메시지 센터

<details markdown="1">
<summary>값과 캡처 보기 (그림 1장)</summary>

- GUI 경로: M365 관리 센터 > 상태 > 메시지 센터

총 469건(수집 464건 기준 집계)이었고, 조치 기한이 있는 게시물 31건 가운데 기한 경과 16건(기한 범위 2026-06-29 ~ 2026-10-05), 30일 내 임박 7건이었습니다. 조직 내 상태 기록은 "예약됨 2, 시작됨 1"로 3건입니다. 10/19 사전 조회 때는 451건이었습니다.

메시지 센터는 변경 전에 알려 주는 채널이라, 놓치면 사용자 문의로 먼저 알게 됩니다. 메시지 센터와 서비스 상태는 운영 업무의 입력이라 담당과 주기가 없으면 위험으로 읽었습니다.

권고 2의 세부: 변경 영향이 큰 건은 변경 관리 문서로 연결합니다. 메시지 센터와 Planner의 동기화 설정은 이번에는 하지 않았습니다.

근거: [메시지 센터](https://learn.microsoft.com/microsoft-365/admin/manage/message-center), [메시지 센터 작업을 Planner로 추적](https://learn.microsoft.com/planner/track-message-center-tasks-planner), [M365 변경 가이드](https://learn.microsoft.com/microsoft-365-apps/best-practices/microsoft-365-change-guide)

![메시지 센터 화면]({{ "/assets/images/2026/10/m09-3-message-center.png" | relative_url }})
*그림 2. M365 관리 센터 > 상태 > 메시지 센터. 받은 편지함에 "469개 항목"이 있고 서비스별(Exchange Online, Teams, Entra 등) 메시지가 나열됩니다. 테넌트 이름은 가렸습니다.*

</details>

#### 서비스 상태와 알림

<details markdown="1">
<summary>값과 캡처 보기 (그림 1장)</summary>

활성 문제는 9건이었습니다. 인시던트 1건(사용자가 마이그레이션을 수행하지 못할 수 있음)과 권고 8건이고, 서비스별로는 SharePoint Online 인시던트 1, Exchange 권고 2, M365 suite 권고 6입니다. 이메일 알림은 체크 해제, 수신자 0이었습니다.

이대로면 장애가 나도 담당자가 먼저 알 방법이 없습니다. 문서상 이메일 알림은 사용자 지정 메뉴에서 켜고, 주소는 최대 2개입니다. 권고 3의 세부: 인시던트와 권고를 구분해 받습니다.

근거: [서비스 상태 보기](https://learn.microsoft.com/microsoft-365/enterprise/view-service-health)

![서비스 상태 화면]({{ "/assets/images/2026/10/m09-4-service-health.png" | relative_url }})
*그림 3. M365 관리 센터 > 상태 > 서비스 상태(2026-10-22 15:41 기준). "Microsoft이(가) 작업 중인 활성 문제"에 인시던트 1건과 권고 여러 건이 나열되고, 서비스 상태 표에서 SharePoint Online 인시던트 1개, Exchange Online 권고 2개, Microsoft 365 suite 권고 6개가 보입니다. 테넌트 이름은 가렸습니다.*

</details>

#### 퇴사자 OneDrive와 동기화

<details markdown="1">
<summary>값과 캡처 보기 (그림 1장)</summary>

삭제된 사용자 OneDrive 보존은 30일로, 설정 범위의 최소였습니다. OneDrive 동기화는 특정 도메인 컴퓨터로 제한하는 옵션이 꺼져 있고 업로드 차단 파일 형식도 없었습니다.

보존 기간 30일이 끝나면 OneDrive는 사이트 모음 휴지통으로 옮겨져 93일 동안 남고, 그 기간에는 PowerShell로 복원할 수 있습니다(문서). 그래도 일반 사용자가 되살릴 수 있는 기간은 30일뿐이라, 인수인계 기간이 길거나 법적 보존 요구가 있으면 짧습니다. 동기화 도메인 제한이 없으면 개인 PC에도 회사 파일이 동기화될 수 있습니다.

권고 4의 세부: 동기화 가능한 기기는 조건부 액세스나 도메인 제한으로 한정합니다.

근거: [OneDrive 보존·삭제](https://learn.microsoft.com/sharepoint/retention-and-deletion), [보존 기간 설정](https://learn.microsoft.com/sharepoint/set-retention), [OneDrive 개요](https://learn.microsoft.com/sharepoint/onedrive-overview), [동기화 계획](https://learn.microsoft.com/sharepoint/plan-file-sync)

![OneDrive 보존 설정 패널]({{ "/assets/images/2026/10/m09-2-od-retention.png" | relative_url }})
*그림 4. SharePoint 관리 센터 > 설정 > 보존 패널. "삭제된 사용자의 OneDrive 보존 일 수"가 30이고, 라이선스 없는 계정은 60일째 읽기 전용, 93일째 보관된다는 안내가 나옵니다. 저장하지 않고 "취소"로 닫았습니다.*

</details>

#### 저장소와 사이트

<details markdown="1">
<summary>값 보기</summary>

활성 사이트 화면에 "1.24 TB 중 24.00 MB 사용"(약 0.002%), 활성 사이트 10개, 삭제된 사이트 0건(보존 93일 안내)이었습니다. 홈의 OneDrive 사용량 카드는 "지금은 이 정보를 가져올 수 없습니다"라고 나와서 활성 사이트 화면을 근거로 삼았습니다. 용량 여유는 충분해 정상으로 봤지만, 샌드박스라 사용량이 거의 없는 것이니 운영 값으로 해석하면 안 됩니다.

사이트 생성은 사용자 생성 허용, 승인 절차 없음, 기본 시간대 UTC-08:00(태평양)이었습니다. 국내 업무 기준과 달라 보고서 시간이 어긋날 수 있어 주의로 판독했습니다. 사용자 만들기 허용 자체는 Teams 생성 권한과 함께 봐야 합니다([Identity 실측 글]({{ "/m365/measure-identity/" | relative_url }})의 그룹 생성 항목).

</details>

#### 릴리스, 지원 요청, Customer Lockbox

<details markdown="1">
<summary>값과 캡처 보기 (그림 1장)</summary>

릴리스 기본 설정은 "모두에게 공개하는 표준 릴리스"로 정상이었습니다. 다만 화면 배너에 대상 릴리스는 2027년 1월 사용 중지라는 안내가 있어, 대상 릴리스 사용자 지정 계획이 있다면 영향을 받습니다.

지원 요청은 서비스 요청 기록 0건("표시할 티켓이 없습니다")이었습니다. 에스컬레이션 경로와 지원 계약(Services Hub)은 확인 불가입니다(5절).

Customer Lockbox 화면은 두 차례 열어 같은 해제 상태를 읽고 저장 없이 닫았습니다. 이 기능은 승인자 역할과 라이선스 조건(문서상 E5 수준 서비스 설명 참고)이 있는데, 이 테넌트가 충족하는지는 확인 불가입니다(5절).

근거: [릴리스 옵션](https://learn.microsoft.com/microsoft-365/admin/manage/release-options-in-office-365), [릴리스 옵션 구성](https://learn.microsoft.com/microsoft-365/admin/manage/configure-release-options), [대상 릴리스 중지](https://learn.microsoft.com/microsoft-365/admin/manage/targeted-release-retirement), [Customer Lockbox 요청](https://learn.microsoft.com/purview/customer-lockbox-requests)

![Customer Lockbox 설정 패널]({{ "/assets/images/2026/10/m09-5-customer-lockbox.png" | relative_url }})
*그림 5. M365 관리 센터 > 설정 > 조직 설정 > 보안 및 개인 정보 > 고객 Lockbox. "모든 데이터 액세스 요청에 승인 필요" 체크가 해제되어 있습니다. 저장 버튼은 누르지 않았습니다(비활성 상태). 테넌트 이름은 가렸습니다.*

</details>

#### 에이전트와 Copilot

<details markdown="1">
<summary>값과 캡처 보기 (그림 2장)</summary>

Copilot 라이선스는 없어 해당 없음입니다. Agent 365 개요에서는 에이전트 레지스트리 346, 소유자 없는 에이전트 0, 보류 요청 0, 예외 0으로 정상이었습니다. 작성자별 내역은 화면 해석이 불확실해 적지 않았습니다.

M365 관리 센터 > 에이전트 > 설정에는 7개 항목(공유, 사용자 액세스, 에이전트 관리 규칙, 에이전트 및 플러그인 액세스, 피드백 공유, 정책 템플릿, 태그)이 있습니다. "에이전트 및 플러그인 액세스"는 Microsoft 빌드, 조직 빌드, 외부 게시자 빌드가 모두 허용이고 외부 게시자는 "모든 외부 게시자"였습니다. "사용자 액세스"는 "모든 사용자"였습니다. 제한 없이 열려 있는 기본 상태이고, 값만 읽고 저장하지 않았습니다. 나머지 5개 항목의 값은 읽지 않았습니다(5절).

![에이전트 및 플러그인 액세스 설정]({{ "/assets/images/2026/10/m14-agent-access.png" | relative_url }})
*그림 6. M365 관리 센터 > 에이전트 > 설정 > 에이전트 및 플러그인 액세스(조회만 하고 저장하지 않음). 허용 유형 3개가 모두 체크되어 있고 외부 게시자는 "모든 외부 게시자".*

![에이전트 사용자 액세스 설정]({{ "/assets/images/2026/10/m15-agent-user-access.png" | relative_url }})
*그림 7. M365 관리 센터 > 에이전트 > 설정 > 사용자 액세스(조회만 하고 저장하지 않음). "모든 사용자"가 선택되어 있습니다.*

</details>

#### DAG 보고서와 Restricted SharePoint Search

<details markdown="1">
<summary>값과 캡처 보기 (그림 1장)</summary>

DAG(데이터 접근 거버넌스) 보고서는 보고서 메뉴에 OneDrive 계정만 있어 찾을 수 없었습니다. 고급 관리 화면을 열어 보니 DAG가 포함 서비스로 나열되고 무료 평가판 등록 버튼만 있었습니다. SharePoint Advanced Management가 활성화되지 않은 상태입니다(조회). 평가판 등록은 관리자 결정 사항이라 누르지 않았습니다.

Restricted SharePoint Search는 포털 화면이 없고 PowerShell 전용입니다. SPO 관리 셸은 Windows용이라 Linux 기반 Cloud Shell(PowerShell 7)에서는 실행하지 못한 것으로 판단했습니다. Windows의 PowerShell 7에서는 `-UseWindowsPowerShell` 옵션으로 불러올 수 있습니다(문서). 현재 값은 확인 불가이고, 로컬 Windows PowerShell에서 SPO 관리자로 연결해 조회할 계획입니다.

고급 관리 화면의 안내 문구에는 "무료 평가판을 시작한 경우 라이선스가 적용되는 데 최대 24시간"이 있습니다. 문서에는 SharePoint 고급 관리를 쓸 수 있는 조건이 다음 셋 중 하나로 되어 있습니다.

1. 조직에 Copilot 라이선스가 할당된 사용자가 1명 이상
2. SharePoint 고급 관리 Plan 1 추가 기능을 구매
3. Microsoft 365 E7에 포함

이 테넌트에는 Copilot 라이선스가 없어 (1)에 해당하지 않습니다.

평가판 약관과 기간은 이 버튼을 눌러야 나오는 화면에 있을 가능성이 높은데, 누르면 곧바로 등록 단계로 넘어갈 수 있어 약관 화면까지 열어 보지 않았습니다. 일반적인 Microsoft 365 평가판은 기간이 끝나면 자동으로 청구가 시작될 수 있다고 문서에 있습니다(SAM 평가판에도 같은 규칙이 적용되는지는 확인 불가). 그래서 결정권자 확인 후 진행하기로 하고 질문으로 남겼습니다.

![SharePoint 고급 관리 화면]({{ "/assets/images/2026/10/m19-sam-trial.png" | relative_url }})
*그림 8. SharePoint 관리 센터 > 고급 관리. 안내 문구와 "무료 평가판에 등록" 버튼이 보이고, 포함된 서비스 목록은 흐리게(비활성) 표시됩니다. 버튼은 누르지 않았습니다.*

Restricted SharePoint Search는 중단 예정이며 2026-07-31부터 새로 켤 수 없고, 대안은 Restricted Content Discovery입니다(문서).

근거: [Restricted SharePoint Search](https://learn.microsoft.com/sharepoint/restricted-sharepoint-search), [데이터 접근 거버넌스 보고서](https://learn.microsoft.com/sharepoint/data-access-governance-reports), [SharePoint Advanced Management](https://learn.microsoft.com/sharepoint/advanced-management)

</details>

#### 보고서와 기기

<details markdown="1">
<summary>값 보기</summary>

사용 현황 보고서(Teams, Office 정품 인증)는 "이 보고서에 대한 데이터가 없습니다"여서 측정 불가입니다. 원인 후보는 보고서 생성 지연(문서 기준 통상 24~72시간)과 샌드박스 활동 부족인데 확정하지 못했습니다. 이름 익명화(사용자, 그룹, 사이트 이름 숨기기)는 켜져 있었고, 설정은 바꾸지 않았습니다. Intune Windows 장치 0, Windows 업데이트 링 0으로 측정 대상이 없습니다.

M365 Apps 관리 센터는 처음 두 번 모두 로딩에서 멈췄습니다. 다시 열어 본 앱 인벤토리(config.office.com)에는 "프로비전 중, 최대 24시간" 안내가 표시되고 목록이 비어 있었습니다. 멈춘 원인은 화면만으로 확정할 수 없었고, 과정은 [관리 센터 로딩 정체 트러블슈팅]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }})에 정리했습니다.

</details>

### 5. 확인 불가로 남은 것

<details markdown="1">
<summary>확인 불가 항목 펼쳐 보기 (10건)</summary>

막힌 곳: M365 Apps 관리 센터 로딩 정체와 "프로비전 중" 안내는 안내된 시간이 지난 뒤 재조회합니다([관리 센터 로딩 정체 트러블슈팅]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }})). 사용 현황 보고서 "데이터 없음"은 시간을 두고 재조회합니다([사용 현황 보고서 트러블슈팅]({{ "/m365/troubleshooting/usage-report-no-data/" | relative_url }})).

- 기본 링크 유형 변경이 이미 만든 링크에 미치는 영향
    - 시도 방법: Microsoft Learn 문서 검색
    - 막힌 이유: 해당 설명을 명시한 문장을 찾지 못함. 설정을 바꿔 시험하는 것은 이번 범위 밖
    - 다음 방법: 문서를 다시 검색하고, 변경 허용 환경에서 시험
- 이미 만든 공유 링크 점검
    - 시도 방법: 링크 목록 측정을 하지 않음
    - 막힌 이유: 이번 측정 항목에서 빠졌음
    - 다음 방법: 링크 목록을 읽어 점검
- DAG 보고서
    - 시도 방법: 보고서 메뉴, 고급 관리 화면
    - 막힌 이유: SharePoint Advanced Management 미활성. 평가판 등록은 결정권자 확인 필요
    - 다음 방법: 라이선스 확보(또는 평가판 약관 확인) 후 보고서 생성(최대 며칠)
- Restricted SharePoint Search 현재 값
    - 시도 방법: 포털 화면 확인, Cloud Shell(Linux, PowerShell 7) 연결 판단
    - 막힌 이유: PowerShell 전용이고 SPO 관리 셸이 Windows용
    - 다음 방법: 로컬 Windows PowerShell에서 SPO 관리자로 연결 후 조회
- SAM 평가판에 일반 평가판의 자동 청구 규칙이 적용되는지
    - 시도 방법: 문서 확인
    - 막힌 이유: 평가판 약관 화면을 열지 않았고 문서에서 확인하지 못함
    - 다음 방법: 결정권자 확인 후 약관 화면 확인
- 지원 계약(Services Hub)과 에스컬레이션 경로
    - 시도 방법: 지원 요청 화면 확인
    - 막힌 이유: 화면에 서비스 요청 0건만 표시되고 지원 계약 정보는 보이지 않음
    - 다음 방법: 지원 계약 담당에게 확인
- Customer Lockbox 조건 충족 여부
    - 시도 방법: 문서 확인
    - 막힌 이유: 문서의 조건과 이 테넌트의 라이선스·역할을 대조하지 못함
    - 다음 방법: 라이선스와 승인자 역할을 문서 조건과 대조
- 에이전트 설정 나머지 5개 항목
    - 시도 방법: 설정 목록 확인(항목 이름만)
    - 막힌 이유: 값을 읽지 않음
    - 다음 방법: 각 항목을 열어 읽기
- 사용 현황 보고서(Teams, Office 활성화)
    - 시도 방법: 보고서 화면 확인
    - 막힌 이유: 데이터 없음(원인 확정 못 함)
    - 다음 방법: 활동 발생 후 24~72시간 뒤 재조회
- M365 Apps 관리 센터 앱 목록
    - 시도 방법: 화면을 열어 목록 읽기
    - 막힌 이유: 처음 두 번은 로딩에서 멈춤, 이후 "프로비전 중, 최대 24시간" 안내만 표시
    - 다음 방법: 안내된 시간이 지난 뒤 재조회

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- 문서(외부 공유, 기본 링크): [외부 공유 켜기·끄기](https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off), [공동 작업 옵션](https://learn.microsoft.com/sharepoint/collaboration-options), [기본 공유 링크 변경](https://learn.microsoft.com/sharepoint/change-default-sharing-link), [사이트별 외부 공유](https://learn.microsoft.com/sharepoint/change-external-sharing-site), [민감도 레이블의 기본 공유 링크](https://learn.microsoft.com/purview/sensitivity-labels-default-sharing-link)
- 문서(OneDrive 보존, 동기화): [OneDrive 보존·삭제](https://learn.microsoft.com/sharepoint/retention-and-deletion), [보존 기간 설정](https://learn.microsoft.com/sharepoint/set-retention), [OneDrive 개요](https://learn.microsoft.com/sharepoint/onedrive-overview), [동기화 계획](https://learn.microsoft.com/sharepoint/plan-file-sync)
- 문서(Restricted SharePoint Search, DAG, SharePoint Advanced Management): [Restricted SharePoint Search](https://learn.microsoft.com/sharepoint/restricted-sharepoint-search), [데이터 접근 거버넌스 보고서](https://learn.microsoft.com/sharepoint/data-access-governance-reports), [SharePoint Advanced Management](https://learn.microsoft.com/sharepoint/advanced-management)
- 문서(메시지 센터): [메시지 센터](https://learn.microsoft.com/microsoft-365/admin/manage/message-center), [메시지 센터 작업을 Planner로 추적](https://learn.microsoft.com/planner/track-message-center-tasks-planner), [M365 변경 가이드](https://learn.microsoft.com/microsoft-365-apps/best-practices/microsoft-365-change-guide)
- 문서(서비스 상태): [서비스 상태 보기](https://learn.microsoft.com/microsoft-365/enterprise/view-service-health)
- 문서(릴리스 옵션, Customer Lockbox): [릴리스 옵션](https://learn.microsoft.com/microsoft-365/admin/manage/release-options-in-office-365), [릴리스 옵션 구성](https://learn.microsoft.com/microsoft-365/admin/manage/configure-release-options), [대상 릴리스 중지](https://learn.microsoft.com/microsoft-365/admin/manage/targeted-release-retirement), [Customer Lockbox 요청](https://learn.microsoft.com/purview/customer-lockbox-requests)
- 조회(공유, 보존, 메시지 센터, 서비스 상태, 에이전트 설정): 위 각 절의 GUI 경로와 그림

</details>
