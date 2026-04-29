def application(environ, start_response):
    status = '200 OK'
    output = b'HELLO TEST - LE SERVEUR REAGIT. SI VOUS VOYEZ CE MESSAGE, LE PROBLEME EST DANS DJANGO (DB OU SETTINGS).'
    response_headers = [('Content-type', 'text/plain; charset=utf-8'), ('Content-Length', str(len(output)))]
    start_response(status, response_headers)
    return [output]
