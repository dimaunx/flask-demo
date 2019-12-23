from flask import Flask, jsonify, request
from yaml import load, FullLoader
import socket
import logging.config

app = Flask(__name__)


@app.route('/echo', methods=['GET'])
def echo():
    return jsonify(request=request.args, server=get_server_ip())


@app.route('/status', methods=['GET'])
def status():
    return jsonify(status='healthy', server=get_server_ip())


def get_server_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    # dummy destination
    s.connect(("1.1.1.1", 1))
    server_ip = s.getsockname()[0]
    s.close()
    return server_ip


if __name__ == '__main__':
    logging.config.dictConfig(load(open('logging.conf'), Loader=FullLoader))
    app.run(port=8000, debug=False, host='0.0.0.0')
