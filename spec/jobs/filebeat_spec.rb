require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'filebeat job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('filebeat') }
  let(:instance) { Bosh::Template::Test::InstanceSpec.new(name:'my-service', az: 'az1', bootstrap: true) }

  filebeat_configuration = %q(
filebeat.prospectors:
- input_type: log
  paths:
    - /var/*.log
output.logstash:
  hosts: ["192.168.1.5:5044"]
)

  describe 'config/filebeat.yml template' do
    let(:template) { job.template('config/filebeat.yml') }

    describe 'with default manifest values' do
      it 'renders properly' do
        expect { template.render({}) }.not_to raise_error
      end
    end

    describe 'with properties' do
      let(:properties) {
        {
          'filebeat' => {
            'environment' => 'env1',
            'configuration' => filebeat_configuration
          }
        }
      }

      it 'renders properly and uses properties' do
        expect { template.render(properties) }.not_to raise_error

        expect( template.render(properties) ).to include('env: env1')

        expect( template.render(properties) ).to include(filebeat_configuration)
      end
    end
  end

  describe 'data/properties.sh template' do
    let(:template) { job.template('data/properties.sh') }

    describe 'with default manifest values' do
      it 'renders properly' do
        expect { template.render({}, spec: instance) }.not_to raise_error
      end
    end

    describe 'with properties' do
      let(:properties) {
        {
          'filebeat' => {
            'environment' => 'env1',
            'configuration' => filebeat_configuration
          }
        }
      }

      it 'renders properly and uses properties with instance' do
        expect { template.render(properties, spec: instance) }.not_to raise_error

        expect( template.render(properties, spec: instance) ).to include("export NAME='my-service'")

        expect( template.render(properties, spec: instance) ).to include('export JOB_INDEX=0')
      end
    end
  end
end