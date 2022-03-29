import sys
import os
import cv2
import shutil
import numpy as np
from string import ascii_uppercase

labels = ['space', 'nothing', 'del']

for c in ascii_uppercase:
    labels.append(c)

if len(sys.argv) > 1:
    labels = [sys.argv[1]]

for label in labels:
    vidfile = 'data/'+label+'.mov'
    if not os.path.isfile(vidfile):
        print('Could not find data for: ' + label)
        continue
    cap = cv2.VideoCapture(vidfile)
    print('Generating data for: ' + label)
    datadir = './' + label + '_resized'
    if os.path.isdir(datadir):
        shutil.rmtree(datadir)
    os.makedirs(datadir)
    count = 0
    while True:
        ret, frame = cap.read()
        if frame is None:
            break
        count += 1
        frame = cv2.resize(frame, (75, 75))
        cv2.imwrite(datadir+'/'+str(count)+'.jpg', frame)
        '''cv2.imshow('Frame'+str(count), frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
        '''
    cap.release()