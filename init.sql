-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS stargifs;

-- Use the created database
USE stargifs;

CREATE TABLE IF NOT EXISTS visitor_counter (
    id INT AUTO_INCREMENT PRIMARY KEY,
    count INT NOT NULL DEFAULT 0
);

-- Initialize the counter with a value
INSERT INTO visitor_counter (count) VALUES (0);

-- Create the 'images' table if it doesn't exist
CREATE TABLE IF NOT EXISTS images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    url VARCHAR(2000) NOT NULL
);

-- Insert some sample cat GIF URLs into the 'images' table
INSERT INTO images (url) VALUES
("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWhVVkX-ECkWuITbkKbOBzEayBLLXwLgqCZQ&s"),
("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQH8RnFlf6AbwIUCD9p03vWkrIXpQn1Hpc8Pw&s"),
("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTunuv7Ntr7YxZKE8_mZFgV2-lsVnJZ4-Cb8g&s"),
("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSiElvS_DJZ5uxm9OqkhsefGEpEVi5cHoelaA&s"),
("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTfcjZ3c6XBJsZsAuQgogcuQAJmBvLIICxm-Q&s");