<head>
  <title>Index of /</title>
</head>

<body>
  <h1>Index of /</h1>
  <ul>
    {% for url in site.static_files %}
    <li><a href="{{ site.baseurl | escape }}{{ url.path | escape }}">{{ url.name | escape }}</a><span>1000.0B</span></li>
    {% endfor %}
  </ul>
</body>
