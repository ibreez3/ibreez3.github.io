---
layout: default
title: Home
---

<h2>Latest Posts</h2>
<ul>
{% for post in site.posts limit: 5 %}
  <li>
    <h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
    <p>{{ post.excerpt }}</p>
    <small>{{ post.date | date: "%B %d, %Y" }}</small>
  </li>
{% endfor %}
</ul>