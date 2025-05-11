
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2)
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),
    stock_quantity INTEGER
);


INSERT INTO orders (customer_name, total_amount) 
VALUES ('Customer 1', 100.50), ('Customer 2', 250.75);

INSERT INTO products (name, price, stock_quantity)
VALUES ('Product A', 25.00, 100), ('Product B', 50.00, 50);
INSERT INTO products (name, price, stock_quantity)
VALUES ('Product A', 25.00, 100), ('Product B', 50.00, 50);
INSERT INTO products (name, price, stock_quantity)
VALUES ('Product A', 25.00, 100), ('Product B', 50.00, 50);
INSERT INTO products (name, price, stock_quantity)
VALUES ('Product A', 25.00, 100), ('Product B', 50.00, 50);
INSERT INTO products (name, price, stock_quantity)
VALUES ('Product A', 25.00, 100), ('Product B', 50.00, 50);



SHOW pool_nodes;

SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;
SELECT * FROM orders;

SHOW pool_nodes;