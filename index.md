
{% for url in site.static_files %}
  <a href="{{ site.baseurl | escape }}{{ url.path | escape }}">{{ url.name | escape }}</a><td>1000.0B</td>
{% endfor %}
