create database sales_db;
use sales_db;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    signup_date DATE
);

INSERT INTO customers (customer_id, customer_name, city, signup_date)
SELECT 
    n,
    CONCAT('Customer_', n),
    ELT(1 + FLOOR(RAND()*5), 'Mumbai', 'Delhi', 'Pune', 'Bangalore', 'Chennai'),
    DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND()*180) DAY)
FROM (
    SELECT a.N + b.N * 10 + 1 n
    FROM 
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
) numbers
WHERE n <= 100;

select*from customers;

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

INSERT INTO products (product_id, product_name, category, price)
SELECT 
    100 + n,
    CONCAT('Product_', n),
    ELT(1 + FLOOR(RAND()*4), 'Electronics', 'Fashion', 'Furniture', 'Home'),
    FLOOR(1000 + RAND()*90000)
FROM (
    SELECT a.N + b.N * 10 + 1 n
    FROM 
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
) numbers
WHERE n <= 30;

select*from customers;

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO orders (order_id, customer_id, product_id, order_date, quantity, total_amount)
SELECT 
    1000 + n,
    FLOOR(1 + RAND()*100),
    FLOOR(101 + RAND()*30),
    DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND()*365) DAY),
    FLOOR(1 + RAND()*5),
    FLOOR(1000 + RAND()*90000)
FROM (
    SELECT a.N + b.N * 10 + c.N * 100 + 1 n
    FROM 
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
    (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
) numbers
WHERE n <= 1000;
select count(*)from orders;
WITH monthly_revenue AS (
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS month,
        SUM(total_amount) AS revenue
    FROM orders
    GROUP BY FORMAT(order_date, 'yyyy-MM')
)

SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / LAG(revenue) OVER (ORDER BY month), 2
    ) AS growth_percentage
FROM monthly_revenue;
select*from customers;
SELECT 
    customer_id,
    SUM(total_amount) AS lifetime_value,
    RANK() OVER (ORDER BY SUM(total_amount) DESC) AS customer_rank
FROM orders
GROUP BY customer_id
LIMIT 5;
SELECT 
    customer_id,
    MAX(order_date) AS last_order_date,
    CURRENT_DATE - MAX(order_date) AS days_inactive
FROM orders
GROUP BY customer_id
HAVING CURRENT_DATE - MAX(order_date) > 90;
WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
    FROM orders
    GROUP BY customer_id
),

cohort_data AS (
    SELECT 
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
        f.cohort_month,
        TIMESTAMPDIFF(MONTH, f.cohort_month, o.order_date) AS month_number
    FROM orders o
    JOIN first_purchase f 
        ON o.customer_id = f.customer_id
)

SELECT 
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_data
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;

WITH product_sales AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(o.quantity) AS total_sold
    FROM orders o
    JOIN products p 
        ON o.product_id = p.product_id
    GROUP BY p.category, p.product_name
)

SELECT 
    category,
    product_name,
    total_sold
FROM (
    SELECT 
        category,
        product_name,
        total_sold,
        DENSE_RANK() OVER (
            PARTITION BY category 
            ORDER BY total_sold DESC
        ) AS ranking
    FROM product_sales
) ranked
WHERE ranking <= 3;

SELECT VERSION();


