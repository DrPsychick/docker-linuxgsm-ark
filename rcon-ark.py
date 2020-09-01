# very simple RCON tool, configured through ENV for docker containers
# inspired by and based on https://github.com/barneygale/MCRcon/blob/master/demo.py

import socket
import collections
import struct

# copied from https://github.com/barneygale/MCRcon
Packet = collections.namedtuple("Packet", ("ident", "kind", "payload"))

class IncompletePacket(Exception):
    def __init__(self, minimum):
        self.minimum = minimum

class LoginFailed(Exception):
    def __init__(self, minimum):
        self.minimum = minimum


def encode_packet(packet):
    """
    Encodes a packet from the given ``Packet` instance. Returns a byte string.
    """

    data = struct.pack("<ii", packet.ident, packet.kind) + packet.payload + b"\x00\x00"
    return struct.pack("<i", len(data)) + data

def decode_packet(data):
    """
    Decodes a packet from the beginning of the given byte string. Returns a
    2-tuple, where the first element is a ``Packet`` instance and the second
    element is a byte string containing any remaining data after the packet.
    """

    if len(data) < 14:
        raise IncompletePacket(14)

    length = struct.unpack("<i", data[:4])[0] + 4
    if len(data) < length:
        raise IncompletePacket(length)

    ident, kind = struct.unpack("<ii", data[4:12])
    payload, padding = data[12:length-2], data[length-2:length]
    assert padding == b"\x00\x00"
    return Packet(ident, kind, payload), data[length:]

def send_packet(sock, packet):
    """
    Send a packet to the given socket.
    """

    sock.sendall(encode_packet(packet))

def receive_packet(sock):
    """
    Receive a packet from the given socket. Returns a ``Packet`` instance.
    """

    data = b""
    while True:
        try:
            return decode_packet(data)[0]
        except IncompletePacket as exc:
            while len(data) < exc.minimum:
                data += sock.recv(exc.minimum - len(data))

def main(host, port, password, cmd):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(3)

    try:
        sock.connect((host, port))

        send_packet(sock, Packet(0, 3, password.encode("utf8")))
        packet = receive_packet(sock)
        if not packet.ident == 0:
            raise LoginFailed("Incorrect password!")

        send_packet(sock, Packet(0, 2, cmd.encode("utf8")))
        packet = receive_packet(sock)
        if packet.ident == 0:
            print(packet.payload.decode("utf8").strip())
    except (ConnectionRefusedError, ConnectionResetError, LoginFailed) as err:
        print(err)
        sock.close()
        sys.exit(1)
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