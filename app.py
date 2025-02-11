from flask import Flask, render_template
import random
import os
from prometheus_client import Counter, generate_latest, start_http_server
from dotenv import load_dotenv

app = Flask(__name__)

# Load environment variables from .env
load_dotenv()

# Create a custom counter metric for visitor count
visitor_counter = Counter('website_visitors', 'Number of visitors to the website')

@app.route('/')
def display_images():
    try:
        # Increment the visitor counter (Prometheus-based counter)
        visitor_counter.inc()

        # SQL query to retrieve image URLs from database (no changes here)
        import mysql.connector
        db_config = { 
            'host': os.getenv('DB_HOST'),
            'user': os.getenv('DB_USER'),
            'password': os.getenv('DB_PASSWORD'),
            'database': os.getenv('DB_NAME')
        }
        cnx = mysql.connector.connect(**db_config)
        cursor = cnx.cursor()

        # SQL query to retrieve image URLs
        query = "SELECT url FROM images"
        cursor.execute(query)

        # Fetch the list of image URLs
        images = cursor.fetchall()

        # Close the cursor and connection
        cursor.close()
        cnx.close()

        # Shuffle images and pick one
        random.shuffle(images)
        image_url = images[0][0] if images else None

        return render_template('index.html', image=image_url, visitor_count=visitor_counter._value.get())

    except mysql.connector.Error as err:
        app.logger.error(f"Database error: {err}")
        return f"Database error: {err}", 500
    
    except Exception as e:
        app.logger.error(f"Unexpected error: {e}")
        return f"Internal server error: {e}", 500

@app.route('/metrics')
def metrics():
    # Expose metrics in Prometheus-compatible format
    return generate_latest(visitor_counter)


@app.route('/metrics')
def metrics():
    """Expose Prometheus metrics, including visitor count from the database."""
    visitor_gauge.set(get_visitor_count())  # Update visitor count
    return Response(generate_latest(), mimetype="text/plain")


if __name__ == "__main__":
    # Start Prometheus metrics server on port 8000
    start_http_server(8000)

    # Run the Flask app on port 5000 (default)
    app.run(host="0.0.0.0", port=int(os.getenv('FLASK_PORT', 5000)))