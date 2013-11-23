# Configuartion Options for guard-autoupload

opts = {
    :protocol => :scp,        # Protocol used to connect to remote host.
    # Possible values are :scp, :sftp and :ftp.
    # Of these :scp is the preferred one for
    # its stability.
    :host => "remote_host",
    # :port => 22,            # Uncomment this if you need to set port to
    # something else than default.
    :user => "username",
    :password => "password",
    :remote => "remote_path",
    :verbose => true,        # if true you get all outputs
    :quiet => false           # if true outputs only on exceptions.
}

guard :autoupload, opts do
  watch(/^((?!Guardfile$).)*$/)
  ignore [%r{^.idea}, %r{^Guardfile}, %r{__jb_old__}, %r{__jb_bak__}]

  # Matches every other file but Guardfile. This way we don't
end
