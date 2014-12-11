# guard-autoupload

Autoupload plugin used for uploading all local changes to remote host.
Uses either SFTP or FTP.

## Installation

Add this line to your application's Gemfile:

    gem 'guard-autoupload'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install guard-autoupload

## Usage

Sample guardfile:

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
        :verbose => false,        # if true you get all outputs
        :quiet => false           # if true outputs only on exceptions.
        :remote_delete => true    # delete the remote file if local file is deleted (defaults to true)
    }

    guard :autoupload, opts do
        watch(/^((?!Guardfile$).)*$/)
        # Matches every other file but Guardfile. This way we don't
        # accidentally upload the credentials.
    end

## Contributing

1. Fork it ( https://github.com/jyrkij/guard-autoupload/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

This guard plugin was written by Jyrki Lilja and is used at FocusFlow.
The code is hevily based on [vincenthu's guard-flopbox][gsftp] and
[bgarret's guard-ftpsync][gftp].

[gsftp]: https://github.com/vincentchu/guard-flopbox
[gftp]: https://github.com/bgarret/guard-ftpsync
