$LOAD_PATH.unshift File.dirname(__FILE__)

require 'guard'
require 'guard/guard'
require 'autoupload/scpsession.rb'
require 'autoupload/sftpsession.rb'
require 'autoupload/ftpsession.rb'

module Guard
    class Autoupload < Guard
        def initialize(watchers = [], options = {})
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
            @verbose = options[:verbose]
            @quiet = options[:quiet] unless verbose?
            output = options.dup
            output[:password] = options[:password].gsub(/./, '*') if options.include? :password
            log "Initialized with watchers #{watchers.inspect}" if verbose?
            log "Initialized with options #{output.inspect}" unless quiet?
        end

        def run_on_change(paths)
            paths.each do |path|
                local_file = File.join(@local, path)
                remote_file = File.join(@remote, path)

                attempts = 0

                begin
                    log "Upload #{local_file} => #{remote_file}" if verbose?
                    @session.upload!(local_file, remote_file)
                    log "Uploaded #{path}" unless quiet?
                rescue => ex
                    log "Exception on uploading #{path}\n#{ex.inspect}"
                    log ex.backtrace.join("\n") if verbose?
                    attempts += 1
                    remote_dir = File.dirname(remote_file)
                    recursively_create_dirs(remote_dir)
                    retry if attempts < 3
                    log "Exceeded 3 attempts to upload #{path}"
                    throw :task_has_failed
                end
            end

            msg = "Uploaded:\n#{paths.join("\n")}"
            ::Guard::Notifier.notify msg, :title => "Uploaded"
        end

        def run_on_removals(paths)
            paths.each do |path|
                remote_file = File.join(@remote, path)

                begin
                    log "Delete #{remote_file}" if verbose?
                    @session.remove!(remote_file)
                rescue => ex
                    log "Exception on deleting #{path}\n#{ex.inspect}"
                    log ex.backtrace.join("\n") if verbose?
                end

                log "Deleted #{path}" unless quiet?
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

        def log(message)
            puts "[#{Time.now}] #{message}"
        end

        def stop
            log "Tearing down connections" unless quiet?
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
                    log "Creating #{new_dir}" if verbose?
                    @session.mkdir!(new_dir)
                rescue => ex
                    log "Cannot create directory #{new_dir}\n#{ex.inspect}"
                    log ex.backtrace.join("\n") if verbose?
                end
            end

            log "Created directory #{remote_dir}" unless quiet?
        end
    end
end
