#!/bin/sh

FILE=./loader
FAKEFNAME="linux_t1.bin"
cat $FILE > /var/lib/tftpboot/$FAKEFNAME
exit 0
