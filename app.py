from flask import Flask, render_template
import random
import os
import mysql.connector
from dotenv import load_dotenv

app = Flask(__name__)

# Load environment variables from .env
load_dotenv()

# Database configuration
db_config = { 
    'host': os.getenv('DB_HOST'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'database': os.getenv('DB_NAME')
}

@app.route('/')
def display_images():
    try:
        # Establish a database connection
        cnx = mysql.connector.connect(**db_config)
        cursor = cnx.cursor()

        # Increment the visitor counter
        cursor.execute("UPDATE visitor_counter SET count = count + 1 WHERE id = 1")
        cnx.commit()

        # Get the current counter value
        cursor.execute("SELECT count FROM visitor_counter WHERE id = 1")
        visitor_count = cursor.fetchone()[0]

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

        return render_template('index.html', image=image_url, visitor_count=visitor_count)
    
    except mysql.connector.Error as err:
        app.logger.error(f"Database error: {err}")
        return f"Database error: {err}", 500
    
    except Exception as e:
        app.logger.error(f"Unexpected error: {e}")
        return f"Internal server error: {e}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv('FLASK_PORT', 5000)))
