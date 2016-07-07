# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_shc_ui
#
# Configures the ui settings for the search heads in a search head cluster

hash = CernerSplunk::DataBag.load(node['splunk']['config']['ui_prefs'], pick_context: ['shc_configs']) || {}
ui_stanzas = CernerSplunk::UI.configure_ui(node, hash)

splunk_template 'shcluster/deployer-configs/ui-prefs.conf' do
  stanzas ui_stanzas
  not_if { ui_stanzas.empty? }
  notifies :run, 'execute[apply-shcluster-bundle]'
end
