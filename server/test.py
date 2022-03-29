import sys
import requests
import base64

if len(sys.argv[1]) < 1:
    print('Error: Please Specify Image')
    sys.exit(1)
filename = sys.argv[1]
URL = 'http://192.168.1.' + '185' + ':3000/asl'

data = {'media': base64.b64encode(open(filename, 'rb').read()) }
res = requests.post(URL, data = data)
'''res = res.json()
print(res['prediction'])'''