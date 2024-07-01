require 'spec_helper'

describe('icinga2', type: :class) do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      case facts[:kernel]
      when 'windows'
        let(:icinga2_conf_dir) { 'C:/ProgramData/icinga2/etc/icinga2' }
      when 'FreeBSD'
        let(:icinga2_conf_dir) { '/usr/local/etc/icinga2' }
      else
        let(:icinga2_conf_dir) { '/etc/icinga2' }
      end

      context 'with defaults' do
        it { is_expected.to contain_package('icinga2').with({ 'ensure' => 'installed' }) }

        it {
          is_expected.to contain_service('icinga2').with(
            {
              'ensure' => 'running',
              'enable' => true,
            },
          )
        }

        it {
          is_expected.to contain_file("#{icinga2_conf_dir}/features-enabled").with(
            {
              'ensure'  => 'directory',
              'purge'   => true,
              'recurse' => true,
            },
          )
        }

        it { is_expected.to contain_icinga2__feature('checker').with({ 'ensure' => 'present' }) }
        it { is_expected.to contain_icinga2__feature('mainlog').with({ 'ensure' => 'present' }) }
        it { is_expected.to contain_icinga2__feature('notification').with({ 'ensure' => 'present' }) }
      end

      if facts[:os]['family'] == 'RedHat'
        context 'with fact os.selinux.enabled => false' do
          let(:facts) do
            super().merge({ os: { family: 'RedHat', selinux: { enabled: false } } })
          end

          it { is_expected.not_to contain_package('icinga2-selinux') }
        end

        context 'with manage_selinux => false' do
          let(:params) do
            { manage_selinux: false }
          end

          it { is_expected.not_to contain_package('icinga2-selinux') }
        end
      end

      context 'with manage_packages => false' do
        let(:params) do
          { manage_packages: false }
        end

        it { is_expected.not_to contain_package('icinga2') }
      end

      context 'with confd => false' do
        let(:params) do
          { confd: false }
        end

        it {
          is_expected.to contain_file("#{icinga2_conf_dir}/icinga2.conf").without_content(%r{^include_recursive \"conf.d\"})
        }
      end

      context "with confd => 'example.d'" do
        let(:params) do
          { confd: "#{icinga2_conf_dir}/example.d" }
        end

        case facts[:kernel]
        when 'windows'
          let(:pre_condition) do
            [
              "file { 'C:/ProgramData/icinga2/etc/icinga2/example.d': ensure => directory, tag => 'icinga2::config::file' }",
              "file { 'C:/ProgramData/icinga2/etc/icinga2/example.d/foo': ensure => file, tag => 'icinga2::config::file' }",
            ]
          end

          it {
            is_expected.to contain_file("#{icinga2_conf_dir}/icinga2.conf").with_content(
              %r{^include_recursive \"C:/ProgramData/icinga2/etc/icinga2/example.d\"},
            )
          }
        when 'FreeBSD'
          let(:pre_condition) do
            [
              "file { '/usr/local/etc/icinga2/example.d': ensure => directory, tag => 'icinga2::config::file' }",
              "file { '/usr/local/etc/icinga2/example.d/foo': ensure => file, tag => 'icinga2::config::file' }",
            ]
          end

          it {
            is_expected.to contain_file("#{icinga2_conf_dir}/icinga2.conf").with_content(
              %r{^include_recursive \"/usr/local/etc/icinga2/example.d\"},
            )
          }
        else
          let(:pre_condition) do
            [
              "file { '/etc/icinga2/example.d': ensure => directory, tag => 'icinga2::config::file' }",
              "file { '/etc/icinga2/example.d/foo': ensure => file, tag => 'icinga2::config::file' }",
            ]
          end

          it {
            is_expected.to contain_file("#{icinga2_conf_dir}/icinga2.conf").with_content(
              %r{^include_recursive \"/etc/icinga2/example.d\"},
            )
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_conf_dir}/example.d").with(
            {
              'ensure' => 'directory',
              'tag'    => 'icinga2::config::file',
            },
          )
        }

        it {
          is_expected.to contain_file("#{icinga2_conf_dir}/example.d/foo").with(
            {
              'ensure' => 'file',
              'tag'    => 'icinga2::config::file',
            },
          ).that_notifies('Class[icinga2::service]')
        }
      end

      context "with constants => { foo => 'bar' }" do
        let(:params) do
          {
            constants: { foo: 'bar' }
          }
        end

        it { is_expected.to contain_file("#{icinga2_conf_dir}/constants.conf").with_content(%r{^const foo = \"bar\"}) }
      end

      context "with plugins => [ 'foo', 'bar' ]" do
        let(:params) do
          {
            plugins: ['foo', 'bar']
          }
        end

        it {
          is_expected.to contain_file("#{icinga2_conf_dir}/icinga2.conf").with_content(
            %r{^include <foo>},
          ).with_content(%r{^include <bar>})
        }
      end

      context 'with ensure => stopped, enable => false' do
        let(:params) do
          {
            ensure: 'stopped',
            enable: false,
          }
        end

        it {
          is_expected.to contain_service('icinga2').with(
            {
              'ensure' => 'stopped',
              'enable' => false,
            },
          )
        }
      end

      context 'with manage_service => false' do
        let(:params) do
          {
            manage_service: false,
          }
        end

        it { is_expected.not_to contain_service('icinga2') }
      end
    end
  end
end
