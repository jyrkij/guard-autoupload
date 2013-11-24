$LOAD_PATH.unshift File.dirname(__FILE__)

require 'guard'
require 'guard/plugin'
require 'autoupload/scpsession.rb'
require 'autoupload/sftpsession.rb'
require 'autoupload/ftpsession.rb'
require 'kconv'

module Guard
    class Autoupload < Plugin
        def initialize(options = {})
            super

            @instance = self
            if options[:protocol] == :scp
                @session = SCPSession.new(
                    options[:host],
                    options[:port] || 22,
                    options[:user],
                    options[:password],
                    self
                )
            elsif options[:protocol] == :sftp
                @session = SFTPSession.new(
                    options[:host],
                    options[:port] || 22,
                    options[:user],
                    options[:password],
                    @instance
                )
            elsif options[:protocol] == :ftp
                @session = FTPSession.new(
                    options[:host],
                    options[:port] || 21,
                    options[:user],
                    options[:password]
                )
            else
                throw :task_has_failed
            end

            @remote = options[:remote]
            @local = Dir.pwd
            @local_subpath = options[:local] || ''
            @verbose = options[:verbose]
            @quiet = options[:quiet] unless verbose?
            output = options.dup
            output[:password] = options[:password].gsub(/./, '*') if options.include? :password

            UI.info("Initialized with watchers #{watchers.inspect}") if verbose?
            UI.info("Initialized with options #{output.inspect}") unless quiet?
        end

        def run_on_change(paths)
            paths.each do |path|
                path = path.encode(Kconv::UTF8, Encoding::UTF8_MAC) if RUBY_PLATFORM.include? "darwin"

                local_file = File.join(@local, path)
                path.sub!(/^#{@local_subpath}/, '')
                remote_file = File.join(@remote, path)

                attempts = 0

                begin
                    UI.info("Upload #{local_file} => #{remote_file}") if verbose?
                    @session.upload!(local_file, remote_file)
                    UI.info("Uploaded #{path}") unless quiet?
                rescue => ex
                    UI.error("Exception on uploading #{path}\n#{ex.inspect.toutf8}")
                    UI.error(ex.backtrace.join("\n")) if verbose?
                    attempts += 1
                    remote_dir = File.dirname(remote_file)
                    recursively_create_dirs(remote_dir)
                    retry if attempts < 3
                    UI.info("Exceeded 3 attempts to upload #{path}")
                    throw :task_has_failed
                end
            end

            msg = "Uploaded:\n#{paths.join("\n")}"
            UI.info(msg)
            ::Guard::Notifier.notify "uploaded", :title => "Uploaded"
        end

        def run_on_removals(paths)
            paths.each do |path|
                path.sub!(/^#{@local_subpath}/, '')
                remote_file = File.join(@remote, path)

                begin
                    UI.info("Delete #{remote_file}") if verbose?
                    @session.remove!(remote_file)
                rescue => ex
                    UI.error("Exception on deleting #{path}\n#{ex.inspect.toutf8}")
                    UI.error(ex.backtrace.join("\n")) if verbose?
                end

                UI.info("Deleted #{path}") unless quiet?
            end

            msg = "Deleted:\n#{paths.join("\n")}"
            ::Guard::Notifier.notify msg, :title => "Deleted"
        end

        def verbose?
            @verbose || false
        end

        def quiet?
            @quiet || false
        end

        def stop
            UI.info("Tearing down connections") unless quiet?
            if @session.is_a? SCPSession
                @session.close
            end
        end

        private

        def recursively_create_dirs(remote_dir)
            new_dir = @remote
            remote_dir.gsub(@remote, "").split("/").each do |dir|
                new_dir = File.join(new_dir, dir)

                begin
                    UI.info("Creating #{new_dir}") if verbose?
                    @session.mkdir!(new_dir)
                rescue => ex
                    UI.info("Cannot create directory #{new_dir}\n#{ex.inspect.toutf8}")
                    UI.info(ex.backtrace.join("\n")) if verbose?
                end
            end

            UI.info("Created directory #{remote_dir}") unless quiet?
        end
    end
end
