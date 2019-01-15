# very simple RCON tool, configured through ENV for docker containers
# inspired by and based on https://github.com/barneygale/MCRcon/blob/master/demo.py

import mcrcon

# python 2 compatibility
try: input = raw_input
except NameError: pass

def main(host, port, password, cmd):
    rcon = mcrcon.MCRcon()
    rcon.connect(host, port, password)
    try:
        response = rcon.command(cmd)
        if response:
            print(response)
    except:
        print("Unexpected error:", sys.exc_info()[0])
        rcon.disconnect()
        sys.exit(1)
    rcon.disconnect()
    sys.exit(0)

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
