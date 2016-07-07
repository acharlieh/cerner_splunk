# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_ui
#
# Configures the ui settings for the system

hash = CernerSplunk::DataBag.load(node['splunk']['config']['ui_prefs'], pick_context: CernerSplunk.keys(node)) || {}
ui_stanzas = CernerSplunk::UI.configure_ui(node, hash)

splunk_template 'system/ui-prefs.conf' do
  stanzas ui_stanzas
  not_if { ui_stanzas.empty? }
  notifies :touch, 'file[splunk-marker]', :immediately
end
