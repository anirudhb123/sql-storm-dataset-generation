
WITH RECURSIVE customer_sales (c_customer_sk, c_first_name, c_last_name, total_sales_quantity, total_sales_amount, level) AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales_amount,
        0 AS level
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) + cs.total_sales_quantity AS total_sales_quantity,
        COALESCE(SUM(ws.ws_net_paid), 0) + cs.total_sales_amount AS total_sales_amount,
        cs.level + 1
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE cs.level < 10  
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_sales_quantity, cs.total_sales_amount, cs.level
),
avg_sales AS (
    SELECT 
        c.c_customer_sk,
        AVG(cs.total_sales_amount) AS avg_sales_amount,
        AVG(cs.total_sales_quantity) AS avg_sales_quantity
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.avg_sales_amount,
        a.avg_sales_quantity
    FROM customer c
    JOIN avg_sales a ON c.c_customer_sk = a.c_customer_sk
    WHERE a.avg_sales_amount > 1000.00 AND a.avg_sales_quantity > 10
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.avg_sales_amount,
    h.avg_sales_quantity,
    ROW_NUMBER() OVER (ORDER BY h.avg_sales_amount DESC) AS rank
FROM high_value_customers h
ORDER BY h.avg_sales_amount DESC
LIMIT 10;
