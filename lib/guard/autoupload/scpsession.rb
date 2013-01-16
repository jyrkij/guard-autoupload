require 'net/ssh/simple'

class SCPSession
    def initialize(host, user, password, caller_ref)
        @host = host
        @user = user
        @password = password.clone
        @caller = caller_ref
    end

    def ss
        Thread.current[:simplessh] ||= Net::SSH::Simple.new({:user => @user, :password => @password})
    end

    def upload!(local, remote)
        ss.scp_ul "#{@host}", "#{local}", "#{remote}"
    end

    def mkdir!(dir)
        check_exists = ss.ssh "#{@host}", "ls -ld #{dir}"
        ss.ssh "#{@host}", "mkdir #{dir}" unless check_exists.stdout
    end

    def remove!(remote)
        ss.ssh @host, "rm #{remote}"
    end

    def rmdir!(dir)
        throw NotImplementedError
    end

    def ls!(dir)
        ss.ssh @host, "ls #{dir}"
    end

    def close
        ss.close
        Thread.current[:simplessh] = nil
    end
end
