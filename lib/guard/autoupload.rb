$LOAD_PATH.unshift File.dirname(__FILE__)

require 'guard'
require 'guard/guard'
require 'net/sftp'
require 'autoupload/ftpsession.rb'

module Guard
    class Autoupload < Guard
        def initialize(watchers = [], options = {})
            if options[:protocol] == :sftp
                @session = Net::SFTP.start(
                    options[:host],
                    options[:user],
                    {
                        :password => options[:password]
                    }
                )
            elsif options[:protocol] == :ftp
                @session = FTPSession.new(
                    options[:host],
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

            log "Initialized with watchers = #{watchers.inspect}" if verbose?
            log "Initialized with options  = #{options.inspect}" unless quiet?

            super
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
               rescue Exception => ex
                    log "Exception on upload #{path}\n#{ex}" if verbose?
                    attempts += 1
                    remote_dir = File.dirname(remote_file)
                    recursively_create_dirs(remote_dir)
                    retry if attempts < 3
                    log "Exceeded 3 attempts to upload #{path}"
                    throw :task_has_failed
                end
            end

            notify("Uploaded:\n#{paths.join("\n")}")
        end

        def run_on_removals(paths)
            paths.each do |path|
                remote_file = File.join(@remote, path)

                begin
                    log "Delete #{remote_file}" if verbose?
                    @session.remove!(remote_file)
                    @session.rmdir!(remote_file)
                rescue Exception
                end

                log "Deleted #{path}" unless quiet?
            end

            notify("Deleted:\n#{paths.join("\n")}")
        end

        private

        def recursively_create_dirs(remote_dir)
            new_dir = @remote
            remote_dir.gsub(@remote, "").split("/").each do |dir|
                new_dir = File.join(new_dir, dir)

                begin
                    log "Creating #{new_dir}" unless quiet?
                    @session.mkdir!(new_dir)
                rescue Exception
                    log "Cannot create directory #{new_dir}"
                    throw :task_has_failed
                end
            end
        end

        def verbose?
            @verbose || false
        end

        def quiet?
            @quiet || false
        end

        def log(message)
            return unless verbose?
            puts "[#{Time.now}] #{message}"
        end
    end
end
