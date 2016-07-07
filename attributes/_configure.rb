# coding: UTF-8
default['splunk']['config']['host'] = node['ec2'] ? node['ec2']['instance_id'] : (node['fqdn'] || node['machinename'] || node['hostname'])

default['splunk']['config']['licenses'] = nil
default['splunk']['config']['ui_prefs'] = nil

# References 0 to many cluster configurations (arrays of Strings of data_bag/data_bag_item)
default['splunk']['config']['clusters'] = []
default['splunk']['config']['roles'] = nil
default['splunk']['config']['authentication'] = nil

# Attributes used for configuring SH clustering
default['splunk']['bootstrap_shc_member'] = false

default['splunk']['free_license'] = false

# Legacy attributes from the aeon-operations cookbook
default['splunk']['main_project_index'] = nil
default['splunk']['monitors'] = []
default['splunk']['apps'] = {}

# Flag attributes for warnings
default['splunk']['flags']['index_checks_fail'] = true

default['splunk']['config']['assumed_index'] = 'main'
