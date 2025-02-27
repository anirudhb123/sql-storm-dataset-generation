
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        0 AS level
    FROM customer c
    WHERE c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_ext_sales_price) AS average_sales,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
    COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), 'No Discount') AS discount_status
FROM CustomerHierarchy ch
JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING total_sales > 1000
ORDER BY total_sales DESC
LIMIT 10;

