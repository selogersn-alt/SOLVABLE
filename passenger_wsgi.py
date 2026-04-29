import os
import sys

def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/plain')])
    return [b"SI VOUS VOYEZ CECI, LE SERVEUR EST REPARE. ON PEUT RELANCER DJANGO."]
