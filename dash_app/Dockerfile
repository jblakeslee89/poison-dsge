FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

COPY app.py .
COPY data/ ./data/

EXPOSE 7860
CMD ["gunicorn", "-b", "0.0.0.0:7860", "--workers", "2", "--timeout", "60", "app:server"]
