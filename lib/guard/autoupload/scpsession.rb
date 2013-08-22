# encoding: utf-8
require 'net/ssh/simple'

class SCPSession
    def initialize(host, port, user, password, caller_ref)
        @host = host
        @port = port
        @user = user
        @password = password
        @caller = caller_ref
        @retry_count = 0
        @max_retries = 1
    end

    def ss
        Thread.current[:simplessh] ||= Net::SSH::Simple.new({:user => @user, :password => @password.clone})
    end

    def upload!(local, remote)
        begin
            ss.scp_put "#{@host}", "#{local}", "#{remote}", :port => @port
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET, Net::SSH::Disconnect
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
            check_exists = ss.ssh "#{@host}", "ls -ld #{dir}", :port => @port
            ss.ssh "#{@host}", "mkdir #{dir}", :port => @port if check_exists.exit_code
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET, Net::SSH::Disconnect
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
            ss.ssh @host, "rm #{remote}", :port => @port
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET, Net::SSH::Disconnect
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
            ss.ssh @host, "ls #{dir}", :port => @port
            # This shouldn't be run if we get an exception
            @retry_count = 0
        rescue Net::SSH::Simple::Error => e
            case e.wrapped
            when Errno::ECONNRESET, Net::SSH::Disconnect
                raise e if @retry_count >= @max_retries
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
