from flask import Flask, Response, render_template
import random
import os
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from dotenv import load_dotenv
import mysql.connector

app = Flask(__name__)

# Load environment variables from .env
load_dotenv()

# Create a custom counter metric for visitor count (Prometheus-based)
visitor_counter = Counter('website_visitors_total', 'Number of visitors to the website')

@app.route('/')
def display_images():
    try:
        db_config = {
            'host': os.getenv('DB_HOST'),
            'user': os.getenv('DB_USER'),
            'password': os.getenv('DB_PASSWORD'),
            'database': os.getenv('DB_NAME')
        }
        cnx = mysql.connector.connect(**db_config)
        cursor = cnx.cursor()

        # Increment visitor counter in the database
        cursor.execute("UPDATE visitor_counter SET count = count + 1 WHERE id = 1")
        cnx.commit()

        # Fetch the latest visitor count from the database (NOT from Prometheus)
        cursor.execute("SELECT count FROM visitor_counter WHERE id = 1")
        visitor_count = cursor.fetchone()[0]  # Get latest count from DB

        cursor.close()
        cnx.close()

        # Debug: Print visitor count to logs
        print(f"Visitor Count (DB): {visitor_count}")

        # Fetch images from DB
        cnx = mysql.connector.connect(**db_config)
        cursor = cnx.cursor()
        cursor.execute("SELECT url FROM images")
        images = cursor.fetchall()
        cursor.close()
        cnx.close()

        # Shuffle images and pick one
        random.shuffle(images)
        image_url = images[0][0] if images else None

        # Send the updated visitor count to the HTML page
        return render_template('index.html', image=image_url, visitor_count=visitor_count)

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
        db_config = { 
            'host': os.getenv('DB_HOST'),
            'user': os.getenv('DB_USER'),
            'password': os.getenv('DB_PASSWORD'),
            'database': os.getenv('DB_NAME')
        }
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Fetch the latest visitor count from the database
        cursor.execute("SELECT count FROM visitor_counter WHERE id = 1")
        visitor_count = cursor.fetchone()[0]
        connection.close()

        # Update the Prometheus counter based on the latest database value
        visitor_counter._value.set(visitor_count)  # Set the counter to match the DB value
    except Exception as e:
        print(f"Error fetching visitor count: {e}")  # Log error

    # Return all metrics in Prometheus format
    return Response(generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST})

if __name__ == "__main__":
    # Start the Flask app on port 5000
    app.run(host="0.0.0.0", port=int(os.getenv('FLASK_PORT', 5000)))
