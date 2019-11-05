# very simple RCON tool, configured through ENV for docker containers
# inspired by and based on https://github.com/barneygale/MCRcon/blob/master/demo.py

import mcrcon
import socket

# python 2 compatibility
try: input = raw_input
except NameError: pass

def main(host, port, password, cmd):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(3)
    sock.connect((host, port))

    try:
        result = mcrcon.login(sock, password)
        if not result:
            print("Incorrect password!")
            return

        response = mcrcon.command(sock, cmd)
        if response:
            print(response)
    except:
        print("Unexpected error:", sys.exc_info()[0])
        sock.close()
        sys.exit(1)
    finally:
        sock.close()
    
    return

if __name__ == '__main__':
    import sys
    args = sys.argv[1:]
    if len(args) != 1:
        print("usage: python rcon.py <command>")
        sys.exit(1)
    import os

    try:
        host = os.environ['RCON_HOST']
        port = int(os.environ['RCON_PORT'])
        password = os.environ['RCON_PASS']
    except:
        print("requires environment variables: RCON_HOST, RCON_PORT and RCON_PASS")
        sys.exit(1)

    main(host, port, password, args[0])
