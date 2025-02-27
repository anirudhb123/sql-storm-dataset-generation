
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_ext_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c_customer_sk,
        COALESCE(cd_gender, 'U') AS gender,
        SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk, cd_gender
),
address_stats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses
    FROM customer_address 
    GROUP BY ca_state
)
SELECT 
    ci.gender,
    COUNT(DISTINCT ci.c_customer_sk) AS number_of_customers,
    MAX(ci.total_spent) AS max_spent,
    MIN(ci.total_spent) AS min_spent,
    SUM(ci.total_spent) AS total_revenue,
    COALESCE(as.unique_addresses, 0) AS address_count
FROM customer_info ci
LEFT JOIN address_stats as ON ci.gender = (CASE WHEN as.unique_addresses > 100 THEN 'M' ELSE 'F' END)
GROUP BY ci.gender
HAVING COUNT(DISTINCT ci.c_customer_sk) > 10
ORDER BY total_revenue DESC
LIMIT 10;
