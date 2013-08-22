require 'net/ftp'

class FTPSession
    RESPAWN_INTERVAL = 60 # in seconds

    def initialize(host, port, user, password)
        @session = Net::FTP.new
        @host = host
        @user = user
        @password = password
        @last_timestamp = Time.new(0)
        @session.connect(@host, port)
        @session.login(@user, @password)
    end

    def upload!(local, remote)
        remote { @session.putbinaryfile(local, remote) }
    end

    def mkdir!(dir)
        remote { @session.mkdir(dir) }
    end

    def remove!(remote)
        remote { @session.delete(remote) }
    end

    def rmdir!(dir)
        remote { @session.rmdir(dir) }
    end

    private

    def remote
        command_start_timestamp = Time.now
        if (command_start_timestamp - @last_timestamp > RESPAWN_INTERVAL)
            @session.close unless @session.last_response == nil
            @session.connect(@host)
            @session.login(@user, @password)
        end
        ret = yield
        @last_timestamp = Time.now
        ret
    end
end
