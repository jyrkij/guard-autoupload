require 'net/ssh/simple'

class SCPSession
    def initialize(host, user, password, caller_ref)
        @host = host
        @user = user
        @password = password.clone
        @caller = caller_ref
        @retry_count = 0
        @max_retries = 1
    end

    def ss
        Thread.current[:simplessh] ||= Net::SSH::Simple.new({:user => @user, :password => @password.clone})
    end

    def upload!(local, remote)
        begin
            ss.scp_ul "#{@host}", "#{local}", "#{remote}"
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET
                raise e if @retry_count >= @max_retries
                @retry_count += 1
                @caller.log "Failed uploading and will try again."
                @caller.log "The reason was #{e}" unless @caller.quiet?
                close
                retry
            else
                raise e
            end
        end
    end

    def mkdir!(dir)
        begin
            check_exists = ss.ssh "#{@host}", "ls -ld #{dir}"
            ss.ssh "#{@host}", "mkdir #{dir}" unless check_exists.stdout
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET
                raise e if @retry_count >= @max_retries
                @retry_count += 1
                @caller.log "Failed making directory and will try again."
                @caller.log "The reason was #{e}" unless @caller.quiet?
                close
                retry
            else
                raise e
            end
        end
    end

    def remove!(remote)
        begin
            ss.ssh @host, "rm #{remote}"
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET
                raise e if @retry_count >= @max_retries
                @retry_count += 1
                @caller.log "Failed removing file and will try again."
                @caller.log "The reason was #{e}" unless @caller.quiet?
                close
                retry
            else
                raise e
            end
        end
    end

    def rmdir!(dir)
        throw NotImplementedError
    end

    def ls!(dir)
        begin
            ss.ssh @host, "ls #{dir}"
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET
                raise e if @retry_count >= @max_retries
                puts @password
                exit
                @retry_count += 1
                @caller.log "Failed listing directory contents and will try again."
                @caller.log "The reason was #{e}" unless @caller.quiet?
                close
                retry
            else
                raise e
            end
        end
    end

    def close
        ss.close
        Thread.current[:simplessh] = nil
    end
end
