from flask import Flask, request
import numpy as np
import base64
import cv2

DEBUG = False

app = Flask(__name__)

if not DEBUG:
    import tensorflow as tf
    import bjoern
    from gevent.pywsgi import WSGIServer
    print('Opening Configuration...')
    with open('model/final_config_30.json', 'r') as file:
        config = file.read()
        model = tf.keras.models.model_from_json(config)
        print('Reading Model Weights...')
        model.load_weights('model/final_weights_30.h5')

    classes = {0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J', 10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S', 19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z', 26: 'del', 27: 'nothing', 28: 'space', 29: 'other'}
    labels = [classes[k] for k in classes.keys()]

@app.route('/asl', methods = ['POST'])
def predict():
    file = request.form['media']
    dec = base64.b64decode(file)
    npimg = np.frombuffer(dec, np.uint8)
    img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
    img = cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
    pred = 'debug'
    conf = '0'
    if not DEBUG:
        frame = cv2.resize(img, (50, 50))
        frame = np.reshape(frame, (1, 50, 50, 3))
        softmax = model.predict(frame)
        pred = labels[np.argmax(softmax)]
        conf = str(round(np.max(softmax) * 100, 2))
        # print(softmax)
        # print(pred)
    else:
        pass
    cv2.imwrite('tmp.jpg', img)
    return {'success': True, 'prediction': pred, 'confidence': conf}, 200

print('Starting Server...')

if not DEBUG:
    '''
    http_server = WSGIServer(("0.0.0.0", 3000), app)
    http_server.serve_forever()
    '''
    bjoern.run(app, "0.0.0.0", 3000)
else:
    app.run(
        debug = False,
        host="0.0.0.0",
        port = 3000
    )