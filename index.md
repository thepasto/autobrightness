  <h1>Index of /</h1>
  <ul>
    {% for url in site.static_files %}
    <li><a href="{{ site.baseurl | escape }}{{ url.path | escape }}">{{ url.name | escape }}</a></li>
    {% endfor %}
  </ul>
