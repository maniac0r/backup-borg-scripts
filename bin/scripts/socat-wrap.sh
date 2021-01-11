#!/bin/bash
exec socat STDIO UNIX-CONNECT:/var/borg/borg-remote.sock
