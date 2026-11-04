---
title: "[Study] Azure 컴퓨팅과 스토리지: VM, Storage account, Redundancy"
date: 2026-10-31 10:10:00 +0900
categories: [study]
phase: 3단계 Azure
seq: 1
tags: [Study, Azure, VM, Storage account, Redundancy, Azure Backup]
excerpt: "게스트 OS에서 끈 VM은 요금이 계속 나옵니다. VM 비용과 가용성, Storage redundancy, 백업과 RPO·RTO를 정리합니다"
---

VM을 게스트 OS 안에서 껐는데 compute 요금이 계속 나온다면 deallocate가 되지 않은 것입니다. 이번 주를 마치면 VM 비용 구조와 가용성 옵션, 스토리지 복제 수준(LRS, ZRS, GRS, GZRS), 백업과 DR 요구를 RPO·RTO로 설명할 수 있게 됩니다.

## 요약

- VM은 포털에서 중지해 deallocated가 되어야 compute 비용이 멈춤
- 스토리지 복제 수준은 막아야 할 장애 범위와 RPO·RTO로 고름
- Access key는 계정 전체 권한이라 SAS나 Entra ID 인증을 씀

12주 학습 로드맵의 9주차입니다. 이전 글은 [Intune 디바이스 관리]({{ "/study/intune-device-management/" | relative_url }}), 다음 글은 [Azure 네트워크 기초]({{ "/study/azure-network-basics/" | relative_url }})이고, 전체 순서는 [클라우드 학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에 있습니다.

---

## 전체 내용

### 1. 이번 주 용어

Virtual machine(VM), VM size·series, Managed disk, Availability set, Availability zone, VM Scale Set(VMSS), Azure Compute Gallery, Azure Bastion, Azure Hybrid Benefit, Reserved Instance, Spot VM, Azure Update Manager, Azure Arc, Storage account, Blob, Azure Files, Redundancy(LRS, ZRS, GRS, GZRS, RA-GRS), Access tier(Hot, Cool, Cold, Archive), SAS, Access key, Azure File Sync, Azure Backup, Recovery Services vault, Azure Site Recovery(ASR), RPO·RTO

### 2. 개념 설명

#### 컴퓨팅(VM)

VM은 compute(VM size), OS·데이터 디스크(Managed disk), NIC, 보통 NSG와 공용 IP로 이루어집니다.

포털에서 중지해 deallocated가 되면 디스크 비용만 남습니다. 게스트 OS 안에서 종료한 stopped 상태는 compute 비용이 계속 나옵니다.

Availability set은 한 데이터센터 안에서 장애 도메인과 업데이트 도메인을 나누고, Availability zone은 데이터센터 단위로 분산합니다. VMSS는 동일한 VM 여러 대를 오토스케일합니다.

비용 절감 방법:

- Azure Hybrid Benefit: 기존 Windows Server, SQL 라이선스 적용
- Reserved Instance: 1년·3년 약정(Azure Reservations의 VM 예약)
    - 문서: 정식 이름은 Azure Reserved VM Instances이며 할인만 주고 용량은 보장하지 않습니다([Azure Reserved VM Instances](https://learn.microsoft.com/azure/virtual-machines/prepay-reserved-vm-instances)).
    - 문서: 워크로드가 자주 바뀌면 시간당 지출 금액을 약정하는 savings plan을 고를 수 있습니다([savings plan과 reservation 비교](https://learn.microsoft.com/azure/cost-management-billing/savings-plan/decide-between-savings-plan-reservation)).
- Spot VM: 중단 가능한 저가 VM

Azure Bastion은 공용 IP 없이 포털에서 RDP·SSH 접속을, Azure Update Manager는 패치를 맡습니다. 온프레미스나 다른 클라우드의 서버는 Azure Arc로 Azure 리소스처럼 등록해 같은 도구로 관리합니다.

#### Storage redundancy

| 수준 | 복제 방식 | 막아 주는 장애 |
|---|---|---|
| LRS | 한 데이터센터 안에서 3중 복제 | 디스크, 랙 장애 |
| ZRS | 한 Region의 3개 AZ에 복제 | 데이터센터 한 곳 장애 |
| GRS | Primary에서 LRS + 보조 Region에 비동기 복제 | Region 전체 장애 |
| GZRS | Primary에서 ZRS + 보조 Region에 비동기 복제 | AZ 장애와 Region 장애 |

RA-GRS·RA-GZRS는 보조 Region 데이터를 읽기용으로 연 변형입니다.

#### 스토리지와 백업의 나머지 개념

Access tier는 Hot, Cool, Cold, Archive 순서로 저장 비용이 낮아지고 접근 비용과 지연은 커집니다.

Access key 대신 쓰는 SAS는 제한된 권한과 만료를 지정합니다.

Azure Backup은 Recovery Services vault에 보관하고, ASR은 다른 Region으로 복제해 장애 시 전환합니다. RPO는 허용 데이터 손실, RTO는 허용 복구 시간입니다.

### 3. 온프레미스로 번역하면

| Azure | 온프레미스 |
|---|---|
| VM | Hyper-V VM |
| Managed disk | VHD |
| Availability zone | 다른 서버실 |
| Azure Files와 File Sync | 파일 서버와 DFS 복제 |
| Update Manager | WSUS와 MECM 패치 |
| Azure Arc | 직접 대응 없음(온프레미스 서버에 에이전트를 깔아 Azure 관리 대상으로 연결하는 방식) |

### 4. 실습 (GUI 우선, 비용이 생기지 않는 범위)

1. Azure 포털 > 가상 머신 > 만들기에서 옵션을 둘러보고, **검토 + 만들기(Review + create)에서 예상 비용만 확인하고 만들지 않습니다.**
2. 스토리지 계정 > 만들기에서 Redundancy 옵션과 설명을 읽고 만들지 않습니다.
3. 기존 VM이나 스토리지가 있으면 개요, 디스크, 네트워킹 탭만 읽습니다.
4. Azure Arc와 Update Manager는 Microsoft Learn(한국어) 문서로 구조만 정리합니다.

### 5. 전문가처럼 말하기

> "Region 장애까지 막아야 하면 GRS나 GZRS, AZ 장애까지면 ZRS를 요구 RPO·RTO에 맞춰 고릅니다."

### 6. 자가 점검

- [ ] LRS, ZRS, GRS, GZRS의 차이를 한 줄씩 말할 수 있다.
- [ ] VM이 stopped와 deallocated일 때 비용이 어떻게 다른지 말할 수 있다.
- [ ] Availability set과 Availability zone의 차이를 말할 수 있다.
- [ ] RPO와 RTO를 구분해서 말할 수 있다.
- [ ] Azure Arc가 해결하는 문제를 한 문장으로 말할 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (5문항)</summary>

- **Redundancy 네 가지**: LRS는 한 데이터센터 3중 복제, ZRS는 한 Region의 3개 AZ 복제, GRS는 LRS + 보조 Region 비동기 복제, GZRS는 ZRS + 보조 Region 비동기 복제입니다.
- **stopped와 deallocated**: 포털에서 중지해 deallocated가 되면 compute 비용이 멈추고 디스크 비용만 남습니다. 게스트 OS에서 종료한 stopped 상태는 compute 비용이 계속 나옵니다.
- **Availability set과 zone**: set은 한 데이터센터 안에서 장애 도메인과 업데이트 도메인을 나누고, zone은 데이터센터 단위로 분산합니다.
- **RPO와 RTO**: RPO는 허용 데이터 손실, RTO는 허용 복구 시간입니다.
- **Azure Arc**: 온프레미스나 다른 클라우드의 서버를 Azure 리소스처럼 등록해 같은 도구로 관리하게 해 줍니다.

</details>

### 7. 영상과 자료 (한글 우선)

- 한글: [Az-900 Azure Fundamentals 2주차](https://www.youtube.com/watch?v=892Nhkhwk4A) (Microsoft Developer Korea, 1시간 56분). 데이터베이스, 스토리지, 네트워크, 가상 머신·컨테이너를 다룹니다. Microsoft Learn(한국어)의 컴퓨팅, 스토리지 모듈도 함께 보세요.
- 영문 보완: AZ-104 공식 시리즈(Microsoft Learn, 전 29편)의 [16편 Configure storage accounts](https://www.youtube.com/watch?v=NKmq1t41Zys), [20편 Introduction to Azure virtual machines](https://www.youtube.com/watch?v=mCMpIUGYI48), [21편 Configure virtual machine availability](https://www.youtube.com/watch?v=Sz6yhVDs4yY). [AZ-104 Full Course - 12 Hours](https://www.youtube.com/watch?v=qXk8_0z_HsU)(Certsqill)는 스토리지 모듈이 1:56:11, 컴퓨팅 모듈이 3:29:08부터입니다.
