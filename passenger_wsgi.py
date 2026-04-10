import os
import sys

def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    return [b"<h1>Test WSGI Reussi</h1><p>Si vous voyez ce message, le serveur fonctionne. Le probleme est donc dans le code Django ou ses dependances.</p>"]
