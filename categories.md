---
title: "Category"
layout: single
permalink: /categories/
author_profile: true
---
{% assign tops = "m365,iam,azure,study,blog" | split: "," %}
{% for top in tops %}
{% assign top_posts = site.posts | where_exp: "p", "p.categories[0] == top" %}
{% if top_posts.size > 0 %}
<h2 id="{{ top }}">{{ site.data.category_names[top] }} <small>({{ top_posts.size }})</small></h2>
{% assign direct = top_posts | where_exp: "p", "p.categories.size < 2" %}
{% for p in direct %}
- [{{ p.title }}]({{ p.url | relative_url }}) <small>{{ p.date | date: "%Y-%m-%d" }}</small>
{% endfor %}
{% assign ts = top_posts | where_exp: "p", "p.categories[1] == 'troubleshooting'" %}
{% if ts.size > 0 %}
<h3>{{ site.data.category_names['troubleshooting'] }} <small>({{ ts.size }})</small></h3>
{% for p in ts %}
- [{{ p.title }}]({{ p.url | relative_url }}) <small>{{ p.date | date: "%Y-%m-%d" }}</small>
{% endfor %}
{% endif %}
{% endif %}
{% endfor %}
