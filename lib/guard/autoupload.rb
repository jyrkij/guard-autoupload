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

            log "Initialized with watchers = #{watchers.inspect}"
            log "Initialized with options  = #{options.inspect}"

            super
        end

        def run_on_change(paths)
            paths.each do |path|
                local_file = File.join(@local, path)
                remote_file = File.join(@remote, path)

                attempts = 0

                begin
                    log "Upload #{local_file} => #{remote_file}"
                    @session.upload!(local_file, remote_file)
                rescue Exception => ex
                    log "Exception on upload #{path}\n#{ex}"
                    attempts += 1
                    remote_dir = File.dirname(remote_file)
                    recursively_create_dirs(remote_dir)
                    retry if attempts < 3
                    log "Exceeded 3 attempts to upload #{path}"
                    throw :task_has_failed
                end

                log("Uploaded:\n#{paths.join("\n")}")
                notify("Uploaded:\n#{paths.join("\n")}")
            end
        end

        def run_on_removals(paths)
            paths.each do |path|
                remote_file = File.join(@remote, path)

                begin
                    log "Delete #{remote_file}"
                    @session.remove!(remote_file)
                    @session.rmdir!(remote_file)
                rescue Exception
                end

                notify("Deleted:\n#{paths.join("\n")}")
            end
        end

        private

        def recursively_create_dirs(remote_dir)
            new_dir = remote
            remote_dir.gsub(remote, "").split("/").each do |dir|
                new_dir = File.join(new_dir, dir)

                begin
                    log "Creating #{new_dir}"
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

        def log(message)
            return unless verbose?
            puts "[#{Time.now}] #{message}"
        end
    end
end
