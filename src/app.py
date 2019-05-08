from flask import Flask, request
from werkzeug.utils import secure_filename
import os

app = Flask(__name__, instance_relative_config=True)
app.config.from_object(os.environ['APP_SETTINGS'])

from tools import upload_file_to_s3

@app.route("/", methods=['GET'])
def index():
    return ""

@app.route("/upload/", methods=['POST'])
def upload():
    if "file_to_upload" not in request.files:
        return "No file_to_upload key in request.files"

    file = request.files["file_to_upload"]

    file.filename = secure_filename(file.filename)
    output = upload_file_to_s3(file, app.config["S3_BUCKET"])

    return str(output)
