# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Provider:: forwarder_monitors
#
# Drop in replacement for the existing splunk_forwarder_monitors
provides :cerner_splunk_forwarder_monitors
provides :splunk_forwarder_monitors

action :install do # ~FC017
  input_stanzas = CernerSplunk::LWRP.convert_monitors(node, new_resource.monitors, new_resource.index)

  file new_resource.app do
    action :nothing
    path CernerSplunk.restart_marker_file
  end

  splunk_app new_resource.app do
    apps_dir "#{node['splunk']['home']}/etc/apps"
    action :create
    local true
    files 'inputs.conf' => input_stanzas
    notifies :touch, "file[#{new_resource.app}]", :immediately
  end
end

action :delete do  # ~FC017
  file new_resource.app do
    action :nothing
    path CernerSplunk.restart_marker_file
  end

  splunk_app new_resource.app do
    apps_dir "#{node['splunk']['home']}/etc/apps"
    action :remove
    notifies :touch, "file[#{new_resource.app}]", :immediately
  end
end
