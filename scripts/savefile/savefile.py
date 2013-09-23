#!/usr/bin/env python

import cgi, os, re
import cgitb; cgitb.enable()

BASEDIR='/tmp/swift/'

try: # Windows requirement
  import msvcrt
  msvcrt.setmode (0, os.O_BINARY) # stdin
  msvcrt.setmode (1, os.O_BINARY) # stdout
except ImportError:
  pass

form = cgi.FieldStorage()

print("Content-Type: text/html\n")
print("\n")
print("<html>\n")
print("<head><title>Om mnom mnom</title></head>\n")
print("<body><h1>Thank you</h1>\n")
print("<pre>")

# filename must be relative
if(os.path.isabs(form['filename'].value)):
  print("Sorry, filename must be relative.")
  print("filename=" + form['filename'].value)
  print("</pre></body></html>\n")
  exit(0)

# No directory escapes
if(form['filename'].value.find('..', 0) != -1):
  print("Sorry, no directory traversal.")
  print("filename=" + form['filename'].value)
  print("</pre></body></html>\n")
  exit(0)

# Make sure target matches remote_host or remote_addr
if( (form['target'].value != os.environ['REMOTE_HOST']) &
    (form['target'].value != os.environ['REMOTE_HOST']+'.localdomain') &
    (form['target'].value != os.environ['REMOTE_ADDR']) &
    (form['target'].value != os.environ['REMOTE_ADDR']+'.localdomain') ):
  print("Value of target does not match allowed host list")
  print("REMOTE_HOST:", os.environ['REMOTE_HOST'])
  print("REMOTE_ADDR:", os.environ['REMOTE_ADDR'])
  print("target:", form['target'].value)
  print("</pre></body></html>\n")
  exit(0)

try:
  os.mkdir(BASEDIR + os.path.dirname(form['filename'].value))
except OSError:
  pass

if(os.path.exists(BASEDIR + form['filename'].value)):
  print("Could not store file: already exists.")
  print("filename:", form['filename'].value)
  print("</pre></body></html>\n")
  exit(0)

open(BASEDIR + form['filename'].value, 'wb').write(form['filecontent'].file.read())

print("</body>\n")
print("</html>\n")
