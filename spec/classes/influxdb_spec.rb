require 'spec_helper'

describe('icinga2::feature::influxdb', type: :class) do
  let(:pre_condition) do
    [
      "class { 'icinga2': features => [], constants => {'NodeName' => 'host.example.org'} }",
    ]
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      case facts[:kernel]
      when 'windows'
        let(:icinga2_conf_dir) { 'C:/ProgramData/icinga2/etc/icinga2' }
        let(:icinga2_pki_dir) { 'C:/ProgramData/icinga2/var/lib/icinga2/certs' }
        let(:icinga2_sslkey_mode) { nil }
        let(:icinga2_user) { nil }
        let(:icinga2_group) { nil }
      when 'FreeBSD'
        let(:icinga2_conf_dir) { '/usr/local/etc/icinga2' }
        let(:icinga2_pki_dir) { '/var/lib/icinga2/certs' }
        let(:icinga2_sslkey_mode) { '0440' }
        let(:icinga2_user) { 'icinga' }
        let(:icinga2_group) { 'icinga' }
      else
        let(:icinga2_conf_dir) { '/etc/icinga2' }
        let(:icinga2_pki_dir) { '/var/lib/icinga2/certs' }
        let(:icinga2_sslkey_mode) { '0440' }
        case facts[:os]['family']
        when 'Debian'
          let(:icinga2_user) { 'nagios' }
          let(:icinga2_group) { 'nagios' }
        else
          let(:icinga2_user) { 'icinga' }
          let(:icinga2_group) { 'icinga' }
        end
      end

      context 'with all defaults' do
        it { is_expected.to contain_icinga2__feature('influxdb').with({ 'ensure' => 'present' }) }

        it {
          is_expected.to contain_concat__fragment('icinga2::object::InfluxdbWriter::influxdb').with(
            { 'target' => "#{icinga2_conf_dir}/features-available/influxdb.conf" },
          ).that_notifies('Class[icinga2::service]')
        }
      end

      context 'with ensure => absent' do
        let(:params) do
          {
            ensure: 'absent',
          }
        end

        it { is_expected.to contain_icinga2__feature('influxdb').with({ 'ensure' => 'absent' }) }
      end

      context "with enable_ssl = true, ssl_key => 'foo', ssl_cert => 'bar', ssl_cacert => 'baz'" do
        let(:params) do
          {
            enable_ssl: true,
            ssl_key: 'foo',
            ssl_cert: 'bar',
            ssl_cacert: 'baz',
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/InfluxdbWriter_influxdb.key").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
              'mode'  => icinga2_sslkey_mode,
            },
          ).with_content(%r{^foo$})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/InfluxdbWriter_influxdb.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^bar$})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/InfluxdbWriter_influxdb_ca.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^baz$})
        }
      end

      context 'with enable_ssl = true, ssl_key_path, ssl_cert_path and ssl_cacert_path set' do
        let(:params) do
          {
            enable_ssl: true,
            ssl_key_path: "#{icinga2_pki_dir}/InfluxdbWriter_influxdb.key",
            ssl_cert_path: "#{icinga2_pki_dir}/InfluxdbWriter_influxdb.crt",
            ssl_cacert_path: "#{icinga2_pki_dir}/InfluxdbWriter_influxdb_ca.crt",
          }
        end

        it {
          is_expected.to contain_concat__fragment('icinga2::object::InfluxdbWriter::influxdb').with_content(%r{ssl_key = "#{icinga2_pki_dir}/InfluxdbWriter_influxdb.key"})
        }

        it {
          is_expected.to contain_concat__fragment('icinga2::object::InfluxdbWriter::influxdb').with_content(%r{ssl_cert = "#{icinga2_pki_dir}/InfluxdbWriter_influxdb.crt"})
        }

        it {
          is_expected.to contain_concat__fragment('icinga2::object::InfluxdbWriter::influxdb').with_content(%r{ssl_ca_cert = "#{icinga2_pki_dir}/InfluxdbWriter_influxdb_ca.crt"})
        }
      end
    end
  end
end
