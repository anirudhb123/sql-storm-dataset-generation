
WITH RECURSIVE CustomerTree AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM store_sales WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales))

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ct.level + 1
    FROM customer c
    JOIN CustomerTree ct ON c.c_customer_sk = ct.c_customer_sk
    WHERE ct.level < 3
),
SalesData AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales, AVG(ws.ws_sales_price) AS avg_price, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    INNER JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
CustomerStats AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, COUNT(DISTINCT cs.ss_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    CONCAT(ct.c_first_name, ' ', ct.c_last_name) AS customer_name,
    sd.total_sales,
    sd.avg_price,
    CASE 
        WHEN cs.customer_count > 100 THEN 'High Value'
        WHEN cs.customer_count BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM CustomerTree ct
JOIN SalesData sd ON ct.c_customer_sk = sd.ws_item_sk
JOIN CustomerStats cs ON cs.cd_demo_sk = ct.c_customer_sk
WHERE cs.customer_count IS NOT NULL
ORDER BY sd.total_sales DESC
LIMIT 10;
