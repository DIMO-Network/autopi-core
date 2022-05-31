
#
# IMPORTANT: These states will only run when minion comes online and is connected to master 
#

include:
  - pending  # Will include pending SLS specified in pillar
  {%- if salt["pillar.get"]("setup:mpcie:module", default="ec2x") in ["ec2x", "bg96"] %}
  - ec2x.startup
  - ec2x.gnss.update
  {%- endif %}

# Run startup modules defined in pillar
{%- for module in salt["pillar.get"]("minion_ext:startup_modules", default=[]) %}
startup-module-{{loop.index}}-executed:
  module.run:
    {%- for key, val in module.iteritems() %}
    - {{ key }}: {{ val|tojson }}
    {%- endfor %}
{%- endfor %}

{%- if salt["pillar.get"]("state", default="REGISTERED") == "REGISTERED" %}
# Ensure release is installed
auto-update-release-during-startup:
  module.run:
    - name: minionutil.update_release
    {%- if salt["pillar.get"]("update_release:automatic", default=False) != "startup" and salt["pillar.get"]("update_release:demand", default=False) != "startup" %}
    # Always retry update of release if failed or pending
    - only_retry: true
    {%- endif %}
{%- endif %}

# Restart minion if restart is pending (after running pending SLS or update release)
restart-minion-if-pending:
  module.run:
    - name: minionutil.request_restart
    - pending: false
    - immediately: true
    - reason: changes_made_during_startup