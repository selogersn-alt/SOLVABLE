def application(environ, start_response):
    status = '200 OK'
    output = b'HELLO LOGER - TEST SERVEUR'
    response_headers = [('Content-type', 'text/plain'), ('Content-Length', str(len(output)))]
    start_response(status, response_headers)
    return [output]
