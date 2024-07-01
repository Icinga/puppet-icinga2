require 'spec_helper'

describe('icinga2::feature::gelf', type: :class) do
  let(:pre_condition) do
    [
      "class { 'icinga2': features => [] }",
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

      context 'with defaults' do
        it { is_expected.to contain_icinga2__feature('gelf').with({ 'ensure' => 'present' }) }

        it {
          is_expected.to contain_icinga2__object('icinga2::object::GelfWriter::gelf').with(
            { 'target' => "#{icinga2_conf_dir}/features-available/gelf.conf" },
          ).that_notifies('Class[icinga2::service]')
        }
      end

      context 'with ensure => absent' do
        let(:params) do
          {
            ensure: 'absent',
          }
        end

        it { is_expected.to contain_icinga2__feature('gelf').with({ 'ensure' => 'absent' }) }
      end

      context "with enable_ssl => true, host => '127.0.0.1', ssl_key => 'foo', ssl_cert => 'bar', ssl_cacert => 'baz'" do
        let(:params) do
          {
            enable_ssl: true,
            ssl_key: 'foo',
            ssl_cert: 'bar',
            ssl_cacert: 'baz',
            host: '127.0.0.1',
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/GelfWriter_gelf.key").with(
            {
              'mode'  => icinga2_sslkey_mode,
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^foo})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/GelfWriter_gelf.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^bar$})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/GelfWriter_gelf_ca.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^baz$})
        }
      end

      context 'with enable_ssl => true, ssl_key_path, ssl_cert_path and ssl_cacert_path set' do
        let(:params) do
          {
            enable_ssl: true,
            ssl_key_path: "#{icinga2_pki_dir}/GelfWriter_gelf.key",
            ssl_cert_path: "#{icinga2_pki_dir}/GelfWriter_gelf.crt",
            ssl_cacert_path: "#{icinga2_pki_dir}/GelfWriter_gelf_ca.crt",
          }
        end

        it {
          is_expected.to contain_concat__fragment('icinga2::object::GelfWriter::gelf').with_content(
            %r{key_path = "#{icinga2_pki_dir}/GelfWriter_gelf.key"},
          )
        }

        it {
          is_expected.to contain_concat__fragment('icinga2::object::GelfWriter::gelf').with_content(
            %r{cert_path = "#{icinga2_pki_dir}/GelfWriter_gelf.crt"},
          )
        }

        it {
          is_expected.to contain_concat__fragment('icinga2::object::GelfWriter::gelf').with_content(
            %r{ca_path = "#{icinga2_pki_dir}/GelfWriter_gelf_ca.crt"},
          )
        }
      end
    end
  end
end
