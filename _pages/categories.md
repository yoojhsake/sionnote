---
title: "Category"
layout: single
permalink: /categories/
author_profile: true
---
작업 글은 **작업을 진행한 순서**대로, 트러블슈팅 글은 **작업 영역별**로 묶었습니다. 글 제목에는 번호를 붙이지 않고, 이 페이지의 위에서 아래 순서가 작업 순서입니다.

{% assign tops = "m365,iam,azure,study,blog" | split: "," %}
{% for top in tops %}
{% assign top_posts = site.posts | where_exp: "p", "p.categories[0] == top" %}
{% if top_posts.size > 0 %}
<h2 id="{{ top }}">{{ site.data.category_names[top] }} <small>({{ top_posts.size }})</small></h2>
{% assign direct = top_posts | where_exp: "p", "p.categories.size < 2" %}
{% assign phased = direct | where_exp: "p", "p.phase" %}
{% assign plain = direct | where_exp: "p", "p.phase == nil" %}
{% if phased.size > 0 %}
{% for ph in site.data.groups.phases %}
{% assign in_ph = phased | where: "phase", ph | sort: "seq" %}
{% if in_ph.size > 0 %}
<h3>{{ ph }}</h3>
{% for p in in_ph %}
- [{{ p.title }}]({{ p.url | relative_url }}) <small>{{ p.date | date: "%Y-%m-%d" }}</small>
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
{% for p in plain %}
- [{{ p.title }}]({{ p.url | relative_url }}) <small>{{ p.date | date: "%Y-%m-%d" }}</small>
{% endfor %}
{% assign ts = top_posts | where_exp: "p", "p.categories[1] == 'troubleshooting'" %}
{% if ts.size > 0 %}
<h3>{{ site.data.category_names['troubleshooting'] }} <small>({{ ts.size }})</small></h3>
{% assign ts_other = ts | where_exp: "p", "p.area == nil" %}
{% for p in ts_other %}
- [{{ p.title }}]({{ p.url | relative_url }}) <small>{{ p.date | date: "%Y-%m-%d" }}</small>
{% endfor %}
{% for ar in site.data.groups.areas %}
{% assign in_ar = ts | where: "area", ar | sort: "seq" %}
{% if in_ar.size > 0 %}
<h4>{{ ar }}</h4>
{% for p in in_ar %}
- [{{ p.title }}]({{ p.url | relative_url }}) <small>{{ p.date | date: "%Y-%m-%d" }}</small>
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
{% endif %}
{% endfor %}
