# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_shc_ui' do
  subject do
    runner = ChefSpec::SoloRunner.new do |node|
      node.set['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.set['splunk']['config']['ui_prefs'] = 'cerner_splunk/ui_prefs'
    end
    runner.converge('cerner_splunk::shc_deployer', described_recipe)
  end

  let(:cluster_config) do
    {
      'receivers' => ['33.33.33.20'],
      'license_uri' => nil,
      'receiver_settings' => {
        'splunktcp' => {
          'port' => '9997'
        }
      },
      'indexes' => 'cerner_splunk/indexes',
      'apps' => 'cerner_splunk/apps',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  let(:ui_prefs) do
    {
      'shc_configs' => {
        'bag' => ':base'
      },
      'shc_deployer' => {
        'bag' => ':base',
        'default' => {
          'dispatch.earliest_time' => '@2d'
        }
      },
      'base' => {
        'default' => {
          'dispatch.earliest_time' => '@d',
          'dispatch.latest_time' => 'now',
          'display.prefs.enableMetaData' => 0,
          'display.prefs.showDataSummary' => 0
        }
      }
    }
  end

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'apps').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'ui_prefs').and_return(ui_prefs)
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the ui-prefs.conf file with the ui preferences' do
    expected_attributes = {
      stanzas: {
        'default' => {
          'dispatch.earliest_time' => '@d',
          'dispatch.latest_time' => 'now',
          'display.prefs.enableMetaData' => 0,
          'display.prefs.showDataSummary' => 0
        }
      }
    }

    expect(subject).to create_splunk_template('shcluster/deployer-configs/ui-prefs.conf').with(expected_attributes)
    expect(subject.splunk_template('shcluster/deployer-configs/ui-prefs.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end
end
