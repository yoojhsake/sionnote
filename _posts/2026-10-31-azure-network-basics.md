---
title: "[Study] Azure 네트워크: VNet, NSG, 하이브리드 연결"
date: 2026-10-31 10:11:00 +0900
categories: [study]
phase: 3단계 Azure
seq: 2
tags: [Study, Azure, VNet, NSG, VPN Gateway, ExpressRoute, Private Endpoint]
excerpt: "A-B, B-C를 피어링해도 A-C는 통하지 않습니다. NSG, hub-and-spoke, VPN·ExpressRoute, Private Endpoint 정리"
---

VNet A-B와 B-C를 피어링했는데 A와 C가 통신하지 못한다면 고장이 아니라 정상입니다. Peering은 전이적이지 않기 때문입니다. 이번 주를 마치면 Subnet과 NSG 설계, hub-and-spoke, VPN과 ExpressRoute, PaaS 사설 연결을 온프레미스 네트워크에 빗대어 설명할 수 있습니다.

## 요약

- spoke끼리 통신하려면 hub에 Firewall을 두고 UDR로 경로를 넘겨야 함
- NSG는 priority 숫자가 작은 규칙부터 평가되며 기본 규칙은 65000번대임
- WAF는 Web Application Firewall과 Well-Architected Framework로 뜻이 갈림

12주 학습 로드맵의 10주차입니다. 이전 글: [Azure 컴퓨팅과 스토리지]({{ "/study/azure-compute-storage/" | relative_url }}) · 다음 글: [Azure 보안과 거버넌스]({{ "/study/azure-security-governance/" | relative_url }}) · 전체 로드맵: [클라우드 학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

VNet, Subnet, CIDR, NSG(Network Security Group), ASG(Application Security Group), UDR(User-defined route), Route table, VNet peering, VPN Gateway(S2S·P2S), ExpressRoute, Virtual WAN, Hub-and-spoke, Azure Firewall, Load Balancer, Application Gateway, WAF, Front Door, Traffic Manager, Private Endpoint, Service Endpoint, Azure DNS, Private DNS zone, NAT Gateway, DDoS Protection

### 2. 개념 설명

#### VNet과 Subnet

VNet의 CIDR 주소 공간을 Subnet으로 나눕니다. Azure는 Subnet마다 주소 5개(네트워크, 게이트웨이, DNS 2개, 브로드캐스트)를 예약합니다. 게이트웨이와 Bastion은 `GatewaySubnet`, `AzureBastionSubnet`이라는 전용 Subnet이 필요합니다.

#### NSG

Subnet이나 NIC에 연결해 인바운드·아웃바운드 트래픽을 허용하거나 차단하는 stateful 필터입니다.

- 기본 규칙: 같은 VNet 안 허용(AllowVnetInBound), 로드밸런서 프로브 허용, 나머지 인바운드 거부(DenyAllInBound). 아웃바운드 기본 규칙은 AllowVnetOutBound, AllowInternetOutBound, DenyAllOutBound
- Service tag로 Azure 서비스 IP 범위를 이름으로 지정합니다.

#### Peering과 하이브리드 연결

Peering은 VNet끼리 연결하며 전이적(transitive)이지 않습니다. 그래서 hub-and-spoke에서는 hub에 Firewall이나 Gateway를 두고 UDR로 경로를 지정합니다.

온프레미스 연결에서 Site-to-site VPN은 인터넷 위의 IPsec 터널이고 ExpressRoute는 통신사업자를 통한 전용 회선입니다. Virtual WAN은 여러 지점을 hub로 묶어 관리하는 서비스입니다.

#### 로드 밸런싱 선택

| 서비스 | 계층 |
|---|---|
| Load Balancer | L4(TCP/UDP) |
| Application Gateway | L7(HTTP/HTTPS, WAF 적용 가능) |
| Front Door | 전역 L7 |
| Traffic Manager | DNS 기반 |

이 주의 WAF는 Web Application Firewall(L7 웹 공격 방어, Application Gateway나 Front Door에 붙임)이고, [11주차]({{ "/study/azure-security-governance/" | relative_url }})의 WAF는 Well-Architected Framework(설계 프레임워크)입니다. 문서: [Azure Web Application Firewall 개요](https://learn.microsoft.com/azure/networking/security/network-security#azure-web-application-firewall)

#### PaaS 접근과 DNS

Private Endpoint는 VNet 안의 사설 IP로 PaaS를 연결합니다. Service Endpoint는 VNet 신원을 서비스에 전달하지만 트래픽은 서비스의 공용 엔드포인트로 갑니다.

Azure 제공 DNS의 가상 IP는 168.63.129.16입니다. Azure에 DC를 두면 VNet DNS 서버를 DC로 지정하고, 외부 이름은 DC나 Private DNS Resolver가 포워딩합니다.

### 3. 온프레미스로 번역하면

| Azure | 온프레미스 |
|---|---|
| VNet | VLAN 묶음과 라우팅 도메인 |
| NSG | L4 ACL |
| Azure Firewall | 중앙 방화벽 |
| VPN Gateway | IPsec VPN 장비 |
| ExpressRoute | 전용 회선 |
| Peering | 라우터 간 직접 연결 |

다른 점은 라우터가 아닌 리소스 설정으로 한다는 것입니다.

### 4. 실습 (GUI 우선, 비용이 생기지 않는 범위)

1. Azure 포털 > 가상 네트워크 > 만들기에서 주소 공간과 서브넷 설정만 읽고 만들지 않습니다.
2. NSG 만들기 화면이나 기존 NSG 규칙에서 기본 규칙(65000번대)을 확인합니다.
3. Microsoft Learn(한국어) "하이브리드 연결 옵션" 문서로 전용 회선과 VPN 비교표를 만듭니다.
4. Hub-and-spoke를 종이에 그려 비전이적 피어링을 표시합니다.

### 5. 전문가처럼 말하기

> "VNet peering은 non-transitive라서 spoke 간 통신은 hub의 Azure Firewall이나 NVA로 UDR을 걸어 넘깁니다."
>
> "PaaS 접근은 private endpoint로 사설 IP를 부여해서 공용 엔드포인트를 닫고, 이름 확인은 private DNS zone으로 합니다."

### 6. 자가 점검

- [ ] NSG 규칙의 평가 순서와 기본 규칙을 말할 수 있다.
- [ ] Peering이 전이적이지 않다는 것의 의미와 우회 방법을 말할 수 있다.
- [ ] S2S VPN과 ExpressRoute의 차이를 말할 수 있다.
- [ ] Load Balancer, Application Gateway, Front Door, Traffic Manager를 계층(L4, L7, 전역, DNS)으로 구분할 수 있다.
- [ ] Private Endpoint와 Service Endpoint의 차이를 말할 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (5문항)</summary>

- **NSG 평가 순서**: priority 숫자가 작은 것부터 평가합니다. 기본 규칙은 AllowVnetInBound, 로드밸런서 프로브 허용, DenyAllInBound입니다.
- **비전이적 Peering**: A-B, B-C를 연결해도 A-C는 통신하지 못합니다. hub에 Azure Firewall이나 NVA를 두고 UDR로 경로를 넘겨 우회합니다.
- **S2S VPN과 ExpressRoute**: S2S VPN은 인터넷 위의 IPsec 터널, ExpressRoute는 통신사업자를 통한 전용 회선입니다.
- **로드 밸런싱 계층**: Load Balancer L4, Application Gateway L7, Front Door 전역 L7, Traffic Manager DNS 기반입니다.
- **Private Endpoint와 Service Endpoint**: Private Endpoint는 VNet 안의 사설 IP로 PaaS를 연결합니다. Service Endpoint는 VNet 신원만 전달하고 트래픽은 서비스의 공용 엔드포인트로 갑니다.

</details>

### 7. 영상·자료 (한글 우선)

- 한글: Azure 네트워크 한글 유튜브는 확인 불가입니다(유튜브 검색으로 찾지 못함). Microsoft Korea [Azure 교육·웨비나 페이지](https://www.microsoft.com/ko-kr/azureall)의 온디맨드 웨비나와 Training Day(무료 등록)에서 네트워크 주제를 찾아 보세요.
- 영문 보완: AZ-104 공식 시리즈(Microsoft Learn, 전 29편)의 [8편 Configure virtual networks](https://www.youtube.com/watch?v=PLwE82PNEpg), [9편 Configure network security groups](https://www.youtube.com/watch?v=6Gr17HqHfUw), [11편 Configure Azure Virtual Network peering](https://www.youtube.com/watch?v=gxvdN8hZRtQ), [12편 routes로 트래픽 제어](https://www.youtube.com/watch?v=EReu507KLUs). [AZ-104 Full Course - 12 Hours](https://www.youtube.com/watch?v=qXk8_0z_HsU)는 네트워킹 모듈이 5:31:32부터입니다.
