# ASL Translator/Communicator

This repository contains all the code for the ASL Translator Project. This is a translation tool that uses camera to predict American Sign Language (ASL) gestures/components and relays that to the user by translating the content and speaking it out
- <code>app/</code>: contains the Swift iOS source code that makes up the main application for ASL Translation
- <code>server/</code>:
    - contains the Python (Flask) HTTP Server that is used to predict ASL information from image requests
    - contains the AI model that does all the ASL prediction (using tensorflow and OpenCV)
- <code>data/</code>: helper repository to generate image data from videos for AI training
- <code>ASL.ipynb</code>: Google Colab script for training the AI that predicts sign language from images

