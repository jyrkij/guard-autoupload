require 'net/ftp'

class FTPSession
    def initialize(host, user, password)
        @session = Net::FTP.new
        @host = host
        @user = user
        @password = password
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
        @session.connect(@host)
        @session.login(@user, @password)
        ret = yield
        @session.close
        ret
    end
end
