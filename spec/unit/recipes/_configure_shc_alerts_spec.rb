# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_shc_alerts' do
  subject do
    runner = ChefSpec::SoloRunner.new do |node|
      node.set['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.set['splunk']['config']['alerts'] = 'cerner_splunk/alerts'
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

  let(:alerts) do
    {
      'shc_configs' => {
        'bag' => ':base',
        'email' => {
          'reportServerEnabled' => false
        }
      },
      'base' => {
        'email' => {
          'mailserver' => 'smtprr.example.com',
          'from' => 'splunk@example.com',
          'reportServerEnabled' => true
        }
      }
    }
  end

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'apps').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'alerts').and_return(alerts)
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the alert_actions.conf file with the appropriate alert configs' do
    expected_attributes = {
      stanzas: {
        'email' => {
          'mailserver' => 'smtprr.example.com',
          'from' => 'splunk@example.com',
          'reportServerEnabled' => false
        }
      }
    }

    expect(subject).to create_splunk_template('shcluster/deployer-configs/alert_actions.conf').with(expected_attributes)
    expect(subject.splunk_template('shcluster/deployer-configs/alert_actions.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end
end
