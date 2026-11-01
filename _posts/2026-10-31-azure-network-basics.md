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

- Azure 네트워크 설계의 뼈대는 VNet 안에서 Subnet을 나누고 NSG로 트래픽을 제어, 온프레미스와는 Site-to-site VPN이나 ExpressRoute로 연결하는 것
- NSG 규칙은 **우선순위(priority) 숫자가 작은 것부터** 평가. 기본 규칙은 65000번대
- VNet peering은 **전이적(transitive)이지 않음**. A-B, B-C를 연결해도 A-C는 통신 못 함. 그래서 hub에 Firewall이나 Gateway를 두고 UDR로 경로 지정
- Load Balancer는 L4, Application Gateway는 L7, Front Door는 전역 L7, Traffic Manager는 DNS 기반
- PaaS는 Private Endpoint로 VNet 안의 사설 IP로 연결, 이름 확인은 Private DNS zone

12주 학습 로드맵의 10주차입니다. 이전 글: [Azure 컴퓨팅과 스토리지]({{ "/study/azure-compute-storage/" | relative_url }}) · 다음 글: [Azure 보안과 거버넌스]({{ "/study/azure-security-governance/" | relative_url }}) · 전체 로드맵: [클라우드 학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

VNet, Subnet, CIDR, NSG(Network Security Group), ASG(Application Security Group), UDR(User-defined route), Route table, VNet peering, VPN Gateway(S2S·P2S), ExpressRoute, Virtual WAN, Hub-and-spoke, Azure Firewall, Load Balancer, Application Gateway, WAF, Front Door, Traffic Manager, Private Endpoint, Service Endpoint, Azure DNS, Private DNS zone, NAT Gateway, DDoS Protection

### 2. 개념 설명

#### VNet과 Subnet

VNet은 CIDR 주소 공간을 가지고, 그 안을 Subnet으로 나눕니다. Azure는 각 Subnet에서 주소 5개(네트워크, 게이트웨이, DNS 2개, 브로드캐스트)를 예약하므로 실제로 쓸 수 있는 주소가 5개 적습니다. 게이트웨이용은 `GatewaySubnet`, Bastion용은 `AzureBastionSubnet`이라는 이름의 전용 Subnet이 필요합니다.

#### NSG

Subnet이나 NIC에 연결해 인바운드·아웃바운드 규칙으로 트래픽을 허용하거나 차단하는 stateful 필터입니다. 규칙은 **우선순위(priority) 숫자가 작은 것부터** 평가됩니다.

- 기본 규칙: 같은 VNet 안 허용(AllowVnetInBound), 로드밸런서 프로브 허용, 나머지 인바운드 거부(DenyAllInBound). 아웃바운드 기본 규칙은 AllowVnetOutBound, AllowInternetOutBound, DenyAllOutBound
- Service tag로 Azure 서비스 IP 범위를 이름으로 지정합니다.

#### Peering과 하이브리드 연결

Peering은 VNet끼리 연결하는 것인데, **전이적(transitive)이지 않아서** A-B와 B-C를 연결해도 A-C는 통신하지 못합니다. 그래서 hub-and-spoke 구성에서는 hub에 Firewall이나 Gateway를 두고 UDR로 경로를 지정합니다.

온프레미스와 잇는 방법으로, Site-to-site VPN은 인터넷 위의 IPsec 터널이고 ExpressRoute는 통신사업자를 통한 전용 회선입니다. Virtual WAN은 여러 지점을 hub로 묶어 관리하는 서비스입니다.

#### 로드 밸런싱 선택

계층으로 구분합니다.

| 서비스 | 계층 |
|---|---|
| Load Balancer | L4(TCP/UDP) |
| Application Gateway | L7(HTTP/HTTPS, WAF 포함) |
| Front Door | 전역 L7 |
| Traffic Manager | DNS 기반 |

WAF라는 약어는 헷갈리기 쉽습니다. 이 주의 WAF는 Web Application Firewall(L7 웹 공격 방어, Application Gateway나 Front Door에 붙임)이고, [11주차]({{ "/study/azure-security-governance/" | relative_url }})의 WAF는 Well-Architected Framework(설계 프레임워크)로 전혀 다른 것입니다. 문서: [Azure Web Application Firewall 개요](https://learn.microsoft.com/azure/networking/security/network-security#azure-web-application-firewall)

#### PaaS 접근과 DNS

Private Endpoint는 VNet 안의 사설 IP로 PaaS를 연결합니다. Service Endpoint는 VNet 신원을 서비스에 전달하지만 트래픽은 서비스의 공용 엔드포인트로 갑니다.

Azure 제공 DNS의 가상 IP는 168.63.129.16입니다. Azure에 DC를 두는 하이브리드 AD 구성에서는 VNet의 DNS 서버를 DC로 지정하고, 외부 이름은 DC나 Private DNS Resolver가 포워딩합니다.

### 3. 온프레미스로 번역하면

| Azure | 온프레미스 |
|---|---|
| VNet | VLAN 묶음과 라우팅 도메인 |
| NSG | L4 ACL |
| Azure Firewall | 중앙 방화벽 |
| VPN Gateway | IPsec VPN 장비 |
| ExpressRoute | 전용 회선 |
| Peering | 라우터 간 직접 연결 |

단, 라우터 설정이 아닌 리소스 설정으로 한다는 점이 다릅니다.

### 4. 실습 (GUI 우선, 비용이 생기지 않는 범위)

1. Azure 포털 > 가상 네트워크 > 만들기 화면에서 주소 공간과 서브넷 설정을 읽습니다. 만들지 않습니다.
2. 네트워크 보안 그룹 만들기 화면이나 기존 NSG의 인바운드·아웃바운드 규칙에서 기본 규칙(65000번대)을 확인합니다.
3. 전용 회선과 VPN 구성은 Microsoft Learn(한국어)에서 "하이브리드 연결 옵션" 문서를 읽고 비교표를 만듭니다.
4. Hub-and-spoke 구성을 종이에 그려 보고 피어링이 전이적이지 않은 이유를 표시합니다.

### 5. 전문가처럼 말하기

> "VNet peering은 non-transitive라서 spoke끼리 통신하려면 hub에 Azure Firewall이나 NVA를 두고 UDR로 경로를 넘깁니다."
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

- 한글: Azure 네트워크 한글 유튜브는 확인 불가입니다(유튜브 검색으로 찾았지만 해당 영상을 찾지 못함). Microsoft Korea의 [Azure 교육·웨비나 페이지](https://www.microsoft.com/ko-kr/azureall)에 온디맨드 웨비나와 Training Day(무료 등록)가 있으니 네트워크 주제를 찾아 보세요.
- 영문 보완: AZ-104 공식 시리즈([1편](https://www.youtube.com/watch?v=6rs-oGmz3pk))에서 가상 네트워킹 편, [AZ-104 Full Course - 12 Hours](https://www.youtube.com/watch?v=qXk8_0z_HsU)
