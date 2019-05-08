import os

class Config(object):
    DEBUG = False
    TESTING = False
    S3_BUCKET = os.environ.get('S3_BUCKET')
    S3_KEY = os.environ.get('S3_KEY')
    S3_SECRET = os.environ.get('S3_SECRET')
    S3_LOCATION = 'http://{}.s3.amazonaws.com/'.format(S3_BUCKET)

class Production(Config):
    DEBUG = False

class Staging(Config):
    DEVELOPMENT = True
    DEBUG = True

class Development(Config):
    DEVELOPMENT = True
    DEBUG = True
    S3_LOCATION = 'http://localhost:4572/{}/'.format(Config.S3_BUCKET)

class Testing(Config):
    TESTING = True
    S3_LOCATION = 'http://localhost:4572/{}/'.format(Config.S3_BUCKET)
