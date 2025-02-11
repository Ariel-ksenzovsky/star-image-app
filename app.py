from flask import Flask, Response, render_template
import random
import os
from prometheus_client import Counter, generate_latest, start_http_server, CONTENT_TYPE_LATEST
from dotenv import load_dotenv

app = Flask(__name__)

# Load environment variables from .env
load_dotenv()

# Create a custom counter metric for visitor count
visitor_counter = Counter('website_visitors_total', 'Number of visitors to the website')

@app.route('/')
def display_images():
    try:
        # Increment the visitor counter (Prometheus-based counter)
        visitor_counter.inc()

        # SQL query to retrieve image URLs from the database
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

        # Display the image and visitor count
        return render_template('index.html', image=image_url, visitor_count=visitor_counter._value.get())

    except mysql.connector.Error as err:
        app.logger.error(f"Database error: {err}")
        return f"Database error: {err}", 500

    except Exception as e:
        app.logger.error(f"Unexpected error: {e}")
        return f"Internal server error: {e}", 500

    # Expose only the counter metrics in Prometheus-compatible format
@app.route('/metrics')
def metrics():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        # Fetch the latest visitor count
        cursor.execute("SELECT count FROM visitor_counter WHERE id = 1")
        visitor_count = cursor.fetchone()[0]
        connection.close()

        # Update the Prometheus gauge with the latest visitor count
        visitor_count_gauge.set(int(visitor_count))
    except Exception as e:
        print(f"Error fetching visitor count: {e}")  # Log error

    # Return all metrics in Prometheus format
    return Response(generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST})


if __name__ == "__main__":
    # Start the Flask app on port 5000
    app.run(host="0.0.0.0", port=int(os.getenv('FLASK_PORT', 5000)))