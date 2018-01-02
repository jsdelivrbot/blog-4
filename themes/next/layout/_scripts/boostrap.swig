{%
  set boot_scripts = [
    'src/bootstrap.js'
  ]
%}

{% for bs in boot_scripts %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ bs }}?v={{ theme.version }}"></script>
{% endfor %}
<script type="text/javascript" src="https://cdn.rawgit.com/knsv/mermaid/7.0.0/dist/mermaid.min.js">
