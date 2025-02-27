
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
top_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS rank
    FROM sales_hierarchy
)
SELECT 
    t.customer_sk,
    t.first_name,
    t.last_name,
    t.gender,
    t.marital_status,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = t.customer_sk) AS order_count,
    COALESCE(t.total_profit, 0) AS total_profit
FROM top_sales t
WHERE t.rank <= 10
ORDER BY total_profit DESC;

SELECT 
    'Total Customers' AS metric,
    COUNT(*) AS count 
FROM customer 
UNION ALL 
SELECT 
    'Active Customers' AS metric,
    COUNT(*) 
FROM customer 
WHERE c_current_address_sk IS NOT NULL;

WITH item_sales AS (
    SELECT 
        is.i_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM item is
    JOIN web_sales ws ON is.i_item_sk = ws.ws_item_sk
    GROUP BY is.i_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(is.total_sales, 0) AS total_sales,
    COALESCE(is.total_profit, 0) AS total_profit,
    (SELECT COUNT(DISTINCT customer.c_customer_sk) 
     FROM web_sales ws 
     JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
     WHERE ws.ws_item_sk = i.i_item_sk) AS unique_customers
FROM item i
LEFT JOIN item_sales is ON i.i_item_sk = is.i_item_sk
WHERE i.i_current_price > 50
ORDER BY total_profit DESC
LIMIT 10;
