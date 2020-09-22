{%- for entry in salt['pillar.get']("wasabi:paths") -%}
{{ entry }}
{% endfor %}
