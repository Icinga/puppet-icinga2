require 'spec_helper'

describe('icinga2::feature::idopgsql', type: :class) do
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
        let(:ido_pgsql_schema_dir) { 'C:/Program Files/icinga2/usr/share/icinga2-ido-pgsql/schema' }
        let(:icinga2_sslkey_mode) { nil }
        let(:icinga2_user) { nil }
        let(:icinga2_group) { nil }
      when 'FreeBSD'
        let(:icinga2_conf_dir) { '/usr/local/etc/icinga2' }
        let(:icinga2_pki_dir) { '/var/lib/icinga2/certs' }
        let(:ido_pgsql_schema_dir) { '/usr/local/share/icinga2-ido-pgsql/schema' }
        let(:icinga2_sslkey_mode) { '0440' }
        let(:icinga2_user) { 'icinga' }
        let(:icinga2_group) { 'icinga' }
      else
        let(:icinga2_conf_dir) { '/etc/icinga2' }
        let(:icinga2_pki_dir) { '/var/lib/icinga2/certs' }
        let(:ido_pgsql_schema_dir) { '/usr/share/icinga2-ido-pgsql/schema' }
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
        let(:params) do
          {
            password: 'foo',
          }
        end

        if facts[:kernel] == 'Linux'
          it { is_expected.to contain_package('icinga2-ido-pgsql').with({ 'ensure' => 'installed' }) }
        end

        if facts[:os]['family'] == 'Debian'
          it {
            is_expected.to contain_file('/etc/dbconfig-common/icinga2-ido-pgsql.conf').with(
              {
                'ensure' => 'file',
                'owner'  => 'root',
                'group'  => 'root',
              },
            )
          }
        end

        it { is_expected.to contain_icinga2__feature('ido-pgsql').with({ 'ensure' => 'present' }) }

        it {
          is_expected.to contain_concat__fragment('icinga2::object::IdoPgsqlConnection::ido-pgsql').with(
            { 'target' => "#{icinga2_conf_dir}/features-available/ido-pgsql.conf" },
          )
        }
      end

      context 'with ensure => absent' do
        let(:params) do
          {
            ensure: 'absent',
            password: 'foo',
          }
        end

        it { is_expected.to contain_icinga2__feature('ido-pgsql').with({ 'ensure' => 'absent' }) }
      end

      context 'with import_schema => true' do
        let(:params) do
          {
            import_schema: true,
            password: 'foo',
          }
        end

        it {
          is_expected.to contain_exec('idopgsql-import-schema').with(
            {
              'user'        => 'root',
              'environment' => ['PGPASSWORD=foo'],
              'command'     => "psql 'host=localhost user=icinga dbname=icinga' -w -f '#{ido_pgsql_schema_dir}/pgsql.sql'",
            },
          )
        }
      end

      if facts[:kernel] == 'Linux'
        context 'with manage_packages => false' do
          let(:params) do
            {
              password: 'foo',
            }
          end

          let(:pre_condition) do
            [
              "class { 'icinga2': features => [], manage_packages => false }",
            ]
          end

          it { is_expected.not_to contain_package('icinga2').with({ 'ensure' => 'installed' }) }
          it { is_expected.not_to contain_package('icinga2-ido-pgsql').with({ 'ensure' => 'installed' }) }
        end
      end

      context "with ssl_mode => verify-full, host => '127.0.0.1', port => 5432, import_schema => true, ssl_key => 'foo', ssl_cert => 'bar', ssl_cacert => 'baz'" do
        let(:params) do
          {
            ssl_mode: 'verify-full',
            ssl_key: 'foo',
            ssl_cert: 'bar',
            ssl_cacert: 'baz',
            host: '127.0.0.1',
            port: 5432,
            import_schema: true,
            password: 'foo',
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.key").with(
            {
              'mode'  => icinga2_sslkey_mode,
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^foo})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^bar$})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql_ca.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^baz$})
        }

        it {
          is_expected.to contain_exec('idopgsql-import-schema').with(
            {
              'user'      => 'root',
              'command'   => "psql 'host=127.0.0.1 user=icinga port=5432 dbname=icinga sslmode=verify-full sslcert=#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.crt " \
                "sslkey=#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.key sslrootcert=#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql_ca.crt' " \
                "-w -f '#{ido_pgsql_schema_dir}/pgsql.sql'",
            },
          )
        }
      end

      context "with ssl_mode => verify-ca, host => '192.168.0.1', port => 5432, import_schema => true, ssl_key => 'foo', ssl_cert => 'bar', ssl_cacert => 'baz'" do
        let(:params) do
          {
            ssl_mode: 'verify-ca',
            ssl_key: 'foo',
            ssl_cert: 'bar',
            ssl_cacert: 'baz',
            host: '192.168.0.1',
            port: 5432,
            import_schema: true,
            password: 'foo',
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.key").with(
            {
              'mode'  => icinga2_sslkey_mode,
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^foo})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^bar$})
        }

        it {
          is_expected.to contain_file("#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql_ca.crt").with(
            {
              'owner' => icinga2_user,
              'group' => icinga2_group,
            },
          ).with_content(%r{^baz$})
        }

        it {
          is_expected.to contain_exec('idopgsql-import-schema').with(
            {
              'user'      => 'root',
              'command'   => "psql 'host=192.168.0.1 user=icinga port=5432 dbname=icinga sslmode=verify-ca sslcert=#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.crt " \
                "sslkey=#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql.key sslrootcert=#{icinga2_pki_dir}/IdoPgsqlConnection_ido-pgsql_ca.crt' " \
                "-w -f '#{ido_pgsql_schema_dir}/pgsql.sql'",
            },
          )
        }
      end
    end
  end
end
