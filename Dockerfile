FROM python:3.7-alpine
COPY src /app
WORKDIR /app
RUN pip install -r requirements.txt
CMD ["python", "app.py"]