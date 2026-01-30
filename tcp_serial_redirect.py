#!/usr/bin/env python3
"""
TCP to Serial Bridge Script
Redirects TCP connections to a serial port
Based on pyserial examples
"""

import sys
import socket
import serial
import threading
import time
import argparse


class SerialToTCP:
    """Bridge between a serial port and TCP socket"""
    
    def __init__(self, serial_port, baudrate, tcp_port, host='0.0.0.0'):
        self.serial_port = serial_port
        self.baudrate = baudrate
        self.tcp_port = tcp_port
        self.host = host
        self.ser = None
        self.server_socket = None
        self.client_socket = None
        self.running = False
        
    def serial_to_socket(self):
        """Read from serial and write to socket"""
        while self.running:
            try:
                if self.ser and self.ser.is_open and self.client_socket:
                    data = self.ser.read(self.ser.in_waiting or 1)
                    if data:
                        self.client_socket.sendall(data)
            except Exception as e:
                print(f"Error in serial_to_socket: {e}")
                time.sleep(0.1)
                
    def socket_to_serial(self):
        """Read from socket and write to serial"""
        while self.running:
            try:
                if self.client_socket and self.ser and self.ser.is_open:
                    data = self.client_socket.recv(1024)
                    if data:
                        self.ser.write(data)
                    else:
                        # Client disconnected
                        print("Client disconnected")
                        self.client_socket.close()
                        self.client_socket = None
                        break
            except Exception as e:
                print(f"Error in socket_to_serial: {e}")
                if self.client_socket:
                    self.client_socket.close()
                    self.client_socket = None
                break
                
    def handle_client(self, client_socket):
        """Handle a client connection"""
        print(f"Client connected from {client_socket.getpeername()}")
        self.client_socket = client_socket
        
        # Start bidirectional forwarding threads
        serial_thread = threading.Thread(target=self.serial_to_socket, daemon=True)
        socket_thread = threading.Thread(target=self.socket_to_serial, daemon=True)
        
        serial_thread.start()
        socket_thread.start()
        
        # Wait for socket thread to finish (client disconnect)
        socket_thread.join()
        
        print("Client handler finished")
        
    def run(self):
        """Main loop to accept connections and bridge to serial"""
        try:
            # Open serial port
            print(f"Opening serial port {self.serial_port} at {self.baudrate} baud...")
            self.ser = serial.Serial(
                port=self.serial_port,
                baudrate=self.baudrate,
                timeout=1
            )
            print(f"Serial port opened successfully")
            
            # Create TCP server socket
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.host, self.tcp_port))
            self.server_socket.listen(1)
            
            print(f"TCP server listening on {self.host}:{self.tcp_port}")
            print("Waiting for connections...")
            
            self.running = True
            
            while self.running:
                try:
                    client_socket, address = self.server_socket.accept()
                    self.handle_client(client_socket)
                except KeyboardInterrupt:
                    print("\nShutting down...")
                    break
                except Exception as e:
                    print(f"Error accepting connection: {e}")
                    time.sleep(1)
                    
        except serial.SerialException as e:
            print(f"Error opening serial port: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
        finally:
            self.cleanup()
            
    def cleanup(self):
        """Clean up resources"""
        self.running = False
        
        if self.client_socket:
            try:
                self.client_socket.close()
            except:
                pass
                
        if self.server_socket:
            try:
                self.server_socket.close()
            except:
                pass
                
        if self.ser and self.ser.is_open:
            try:
                self.ser.close()
            except:
                pass
        
        print("Cleanup complete")


def main():
    parser = argparse.ArgumentParser(
        description='Serial to TCP bridge',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument(
        'serial_port',
        help='Serial port (e.g., /dev/ttyUSB0, COM1)'
    )
    
    parser.add_argument(
        'baudrate',
        type=int,
        help='Baud rate (e.g., 9600, 19200, 115200)'
    )
    
    parser.add_argument(
        '-p', '--port',
        dest='tcp_port',
        type=int,
        default=4999,
        help='TCP port to listen on'
    )
    
    parser.add_argument(
        '-H', '--host',
        dest='host',
        default='0.0.0.0',
        help='Host address to bind to'
    )
    
    args = parser.parse_args()
    
    bridge = SerialToTCP(
        serial_port=args.serial_port,
        baudrate=args.baudrate,
        tcp_port=args.tcp_port,
        host=args.host
    )
    
    bridge.run()


if __name__ == '__main__':
    main()
