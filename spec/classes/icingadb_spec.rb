require 'spec_helper'

describe('icinga2::feature::icingadb', type: :class) do
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
        let(:icinga2_sslfile_owner) { nil }
        let(:icinga2_sslfile_mode) { nil }
        let(:icinga2_group) { nil }
      when 'FreeBSD'
        let(:icinga2_conf_dir) { '/usr/local/etc/icinga2' }
        let(:icinga2_pki_dir) { '/var/lib/icinga2/certs' }
        let(:icinga2_sslkey_mode) { '0440' }
        let(:icinga2_sslfile_owner) { 'icinga' }
        let(:icinga2_sslfile_mode) { '0640' }
        let(:icinga2_group) { 'icinga' }
      else
        let(:icinga2_conf_dir) { '/etc/icinga2' }
        let(:icinga2_pki_dir) { '/var/lib/icinga2/certs' }
        let(:icinga2_sslkey_mode) { '0440' }
        let(:icinga2_sslfile_mode) { '0640' }
        case facts[:os]['family']
        when 'Debian'
          let(:icinga2_sslfile_owner) { 'nagios' }
          let(:icinga2_group) { 'nagios' }
        else
          let(:icinga2_sslfile_owner) { 'icinga' }
          let(:icinga2_group) { 'icinga' }
        end
      end

      context 'with defaults' do
        it {
          is_expected.to contain_icinga2__feature('icingadb').with({ 'ensure' => 'present' })
        }

        it {
          is_expected.to contain_icinga2__object('icinga2::object::IcingaDB::icingadb').with(
            { 'target' => "#{icinga2_conf_dir}/features-available/icingadb.conf" },
          ).that_notifies('Class[icinga2::service]')
        }
      end

      context 'with ensure => absent' do
        let(:params) do
          {
            ensure: 'absent',
          }
        end

        it { is_expected.to contain_icinga2__feature('icingadb').with({ 'ensure' => 'absent' }) }
      end

      context 'with enable_tls => true, tls_key => foo, tls_cert => bar, tls_cacert => baz' do
        let(:params) do
          {
            enable_tls: true,
            tls_key: 'foo',
            tls_cert: 'bar',
            tls_cacert: 'baz',
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IcingaDB-icingadb.key").with(
            {
              'mode' => icinga2_sslkey_mode,
              'owner' => icinga2_sslfile_owner,
              'group' => icinga2_group,
            },
          ).with_content(%r{^foo})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IcingaDB-icingadb.crt").with(
            {
              'mode' => icinga2_sslfile_mode,
              'owner' => icinga2_sslfile_owner,
              'group' => icinga2_group,
            },
          ).with_content(%r{^bar})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IcingaDB-icingadb_ca.crt").with(
            {
              'mode' => icinga2_sslfile_mode,
              'owner' => icinga2_sslfile_owner,
              'group' => icinga2_group,
            },
          ).with_content(%r{^baz})
        }
      end

      context 'with enable_tls => true, tls_key => foo, tls_key_file => foobar.key, tls_cert => foo, tls_cert_file => foobar.crt, tls_cacert => baz, tls_cacert_file => foobar_ca.crt' do
        let(:params) do
          {
            enable_tls: true,
            tls_key: 'foo',
            tls_key_file: "#{icinga2_pki_dir}/foobar.key",
            tls_cert: 'bar',
            tls_cert_file: "#{icinga2_pki_dir}/foobar.crt",
            tls_cacert: 'baz',
            tls_cacert_file: "#{icinga2_pki_dir}/foobar_ca.crt",
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/foobar.key").with(
            {
              'mode' => icinga2_sslkey_mode,
              'owner' => icinga2_sslfile_owner,
              'group' => icinga2_group,
            },
          ).with_content(%r{^foo})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/foobar.crt").with(
            {
              'mode' => icinga2_sslfile_mode,
              'owner' => icinga2_sslfile_owner,
              'group' => icinga2_group,
            },
          ).with_content(%r{^bar})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/foobar_ca.crt").with(
            {
              'mode' => icinga2_sslfile_mode,
              'owner' => icinga2_sslfile_owner,
              'group' => icinga2_group,
            },
          ).with_content(%r{^baz})
        }
      end
    end
  end
end
