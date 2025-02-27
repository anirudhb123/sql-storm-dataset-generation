
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_sales_price) > 1000
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(ws.ws_sales_price) AS total_web_sales
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_state IS NOT NULL
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
    HAVING
        SUM(ws.ws_sales_price) > 5000
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_state,
    COALESCE(sd.total_sales, 0) AS web_item_sales,
    CASE
        WHEN cs.total_web_sales > 10000 THEN 'High Value'
        WHEN cs.total_web_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = cs.c_customer_sk) AS store_visits,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cs.c_customer_sk) AS catalog_purchases
FROM
    customer_sales cs
LEFT JOIN sales_data sd ON cs.c_customer_sk = sd.ws_item_sk
WHERE
    sd.sales_rank <= 10
ORDER BY
    cs.total_web_sales DESC;
