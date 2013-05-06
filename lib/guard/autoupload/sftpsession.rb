require 'net/sftp'

class SFTPSession
    def initialize(host, port, user, password, caller_ref)
        @host = host
        @port = port
        @user = user
        @password = password
        @session = Net::SFTP.start(
            @host,
            @user,
            :password => @password,
            :port => @port
        )
        @caller = caller_ref
    end

    def upload!(local, remote)
        remote { @session.upload!(local, remote) }
    end

    def mkdir!(dir)
        begin
            remote { @session.lstat!(dir) }
            exists = true
        rescue Net::SFTP::StatusException
            exists = false
        end
        remote { @session.mkdir!(dir) } unless exists
    end

    def remove!(remote)
        stat = remote { @session.lstat!(remote) }
        remote { @session.remove!(remote) } if stat.file?
        remote { @session.rmdir!(remote) } if stat.directory?
    end

    def rmdir!(dir)
        remote { @session.rmdir!(dir) }
    end

    private

    def remote
        begin
            ret = yield
        rescue => e
            case e
            when Errno::ECONNRESET
                @caller.log "Connection resetted by remote. Reconnecting." unless @caller.quiet?
                @session = Net::SFTP.start(
                    @host,
                    @user,
                    :password => @password,
                    :port => @port
                )
                ret = yield
            else
                raise
            end
        end
        ret
    end
end
