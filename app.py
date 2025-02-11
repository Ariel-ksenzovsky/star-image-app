from flask import Flask, render_template, Response
import random
import os
import mysql.connector
from prometheus_client import Counter, Gauge, generate_latest
from flask_prometheus_metrics import register_metrics, metric_summary
from dotenv import load_dotenv

app = Flask(__name__)

# Load environment variables
load_dotenv()

# Custom Prometheus metrics
visitor_counter = Counter("website_visitors", "Number of visitors to the website")
visitor_gauge = Gauge("website_visitors_total", "Current number of visitors from DB")


def get_visitor_count():
    """Fetch visitor count from the database."""
    try:
        db_config = {
            "host": os.getenv("DB_HOST"),
            "user": os.getenv("DB_USER"),
            "password": os.getenv("DB_PASSWORD"),
            "database": os.getenv("DB_NAME"),
        }
        cnx = mysql.connector.connect(**db_config)
        cursor = cnx.cursor()

        query = "SELECT COUNT(*) FROM visitors"
        cursor.execute(query)
        count = cursor.fetchone()[0]

        cursor.close()
        cnx.close()
        return count
    except mysql.connector.Error as err:
        app.logger.error(f"Database error: {err}")
        return 0


@app.route("/")
@metric_summary("homepage_requests_by_status", "Request count by status", labels={"status": lambda r: r.status_code})
def display_images():
    try:
        visitor_counter.inc()  # Increment Prometheus counter

        visitor_count = get_visitor_count()
        visitor_gauge.set(visitor_count)  # Update Prometheus gauge

        db_config = {
            "host": os.getenv("DB_HOST"),
            "user": os.getenv("DB_USER"),
            "password": os.getenv("DB_PASSWORD"),
            "database": os.getenv("DB_NAME"),
        }
        cnx = mysql.connector.connect(**db_config)
        cursor = cnx.cursor()

        query = "SELECT url FROM images"
        cursor.execute(query)
        images = cursor.fetchall()

        cursor.close()
        cnx.close()

        random.shuffle(images)
        image_url = images[0][0] if images else None

        return render_template("index.html", image=image_url, visitor_count=visitor_count)

    except mysql.connector.Error as err:
        app.logger.error(f"Database error: {err}")
        return f"Database error: {err}", 500

    except Exception as e:
        app.logger.error(f"Unexpected error: {e}")
        return f"Internal server error: {e}", 500


@app.route("/metrics")
def metrics():
    """Expose Prometheus metrics, including visitor count."""
    visitor_gauge.set(get_visitor_count())
    return Response(generate_latest(), mimetype="text/plain")


# Register flask_prometheus_metrics middleware
register_metrics(app, app_version="1.0.0", app_config="production")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("FLASK_PORT", 5000)))
