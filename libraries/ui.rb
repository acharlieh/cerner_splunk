# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: ui.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure ui prefs in a Splunk system
  module UI
    def self.configure_ui(node, hash)
      hash = hash.clone
      default_coords = CernerSplunk::DataBag.to_a node['splunk']['config']['ui_prefs']
      bag = CernerSplunk::DataBag.load hash.delete('bag'), default: default_coords

      ui_stanzas =
        if bag
          bag.merge(hash) do |_key, default_hash, override_hash|
            default_hash.merge(override_hash)
          end
        else
          hash
        end
      fail 'Unexpected property \'bag\'' if ui_stanzas.delete('bag')
      ui_stanzas
    end
  end
end
