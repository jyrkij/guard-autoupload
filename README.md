guard-autoupload
================

Autoupload plugin used for uploading all local changes to remote host.
Uses either SFTP or FTP.

Usage
-----

Sample guardfile:

    opts = {
        :protocol => :sftp,       # protocol used to connect to remote host
                                  # either sftp or ftp
        :host => "remote_host",
        :user => "username",
        :password => "password",
        :remote => "remote_path",
        :verbose => true          # the amount of output
    }

    group 'autoupload' do
        guard 'autoupload', opts do
            watch(/.*/)
        end
    end

Dependencies
------------

 - guard
 - Net::SFTP

Author
------

This guard plugin was written by Jyrki Lilja and is used at FocusFlow.
The code is hevily based on [vincenthu's guard-flopbox][gsftp] and
[bgarret's guard-ftpsync][gftp].

[gsftp]: https://github.com/vincentchu/guard-flopbox
[gftp]: https://github.com/bgarret/guard-ftpsync

