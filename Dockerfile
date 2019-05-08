FROM python:3.6.4-alpine3.7

RUN apk update \
    && apk add --upgrade \
    && pip install --upgrade pip

COPY src/requirements.txt /app/

RUN pip install -r /app/requirements.txt

EXPOSE 5000

WORKDIR /app/

COPY src/ /app/

ENV FLASK_APP=app.py

CMD ["flask", "run", "--host=0.0.0.0"]
