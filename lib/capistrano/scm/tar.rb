require 'capistrano/scm/tar/version'
require 'capistrano/scm/plugin'

module Capistrano
  class SCM
    class Tar
      # Capistrano Plugin for deploying Tarballs
      class Plugin < ::Capistrano::SCM::Plugin
        def set_defaults; end

        def self.authenticate(req)
          return unless ENV['http_user']
          return req.basic_auth ENV['http_user'] unless ENV['http_password']

          req.baseic_auth ENV['http_user'], ENV['http_password']
        end

        def self.revision
          ::File.basename(ENV['package_uri'] || ENV['package']).split('.')[0]
        end

        def self.curl_auth
          return '' unless ENV['http_user']

          str = "-u #{ENV['http_user']}"
          "#{str}:#{ENV['http_password']}" if ENV['http_password']
        end

        def self.download_package(tmp)
          uri = URI(ENV['package_uri'])
          Net::HTTP.start(uri.host, uri.port) do |http|
            req = Net::HTTP::Get.new(uri)
            authenticate(req)
            http.request req do |resp|
              resp.read_body do |chunk|
                tmp.write chunk
              end
            end
          end
        end

        def self.find_package
          return ::File.open(ENV['package']) unless ENV['package_uri']

          require 'net/http'
          require 'tempfile'
          tmp = ::Tempfile.new revision(ENV['package_uri'])
          tmp.binmode
          download_package(tmp)
          tmp
        end

        def self.cleanup(tmp)
          tmp.close
          return unless ENV['package_uri']

          tmp.unlink
        end

        def self.with_package_file
          pkg = find_package
          yield(pkg)
          cleanup pkg
        end

        def self.compression_agent_valid?
          return unless ENV['compression_agent']

          %(j J y Z).include?(ENV['compression_agent'])
        end

        def self.compression
          return '' if ENV['compression_agent'] == 'none'

          return "-#{ENV['compression_agent']}" if compression_agent_valid?

          '-z'
        end

        def self.validate!
          usage unless ENV['package_uri'] || ENV['package']
        end

        def self.usage
          abort 'capistrano-scm-tar:'\
                " 'package=<path>' or 'package_uri=URI'"
        end

        def define_tasks
          namespace :tar do
            task :create_release do
              ::Capistrano::SCM::Tar::Plugin.validate!

              on release_roles :all do
                # Make temporary File for artifact
                tmp = capture 'mktemp'

                if ENV['remote'] && ENV['package_uri']
                  execute :curl, '-sS',
                          ::Capistrano::SCM::Tar::Plugin.curl_auth,
                          ENV['package_uri'], '-o', tmp
                else
                  ::Capistrano::SCM::Tar::Plugin.with_package_file do |pkg|
                    upload! pkg.path, tmp
                  end
                end

                # Retrieve the compress mode from Env
                compression = ::Capistrano::SCM::Tar::Plugin.compression

                # Expand Tarball
                execute :mkdir, '-p', release_path, '&&', :tar, compression,
                        '-xpf', tmp, '-C', release_path, ';', :rm, tmp

                # Update revision
                set :current_revision, ::Capistrano::SCM::Tar::Plugin.revision
              end
            end

            task :check
            task :set_current_revision
          end
        end

        def register_hooks
          after 'deploy:new_release_path', 'tar:create_release'
        end
      end
    end
  end
end
