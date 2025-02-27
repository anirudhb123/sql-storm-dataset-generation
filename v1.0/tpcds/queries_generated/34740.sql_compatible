
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY ws.web_site_sk
    
    UNION ALL
    
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) + ss.total_sales,
        COUNT(DISTINCT ws.ws_order_number) + ss.total_orders
    FROM web_sales ws
    JOIN sales_summary ss ON ws.web_site_sk = ss.web_site_sk
    WHERE ws.ws_sold_date_sk < (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY ws.web_site_sk
),
purchase_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
),
customer_ranked AS (
    SELECT 
        pd.c_customer_sk,
        pd.c_first_name,
        pd.c_last_name,
        pd.total_spent,
        pd.number_of_orders,
        RANK() OVER (PARTITION BY pd.c_customer_sk ORDER BY pd.total_spent DESC) AS rank
    FROM purchase_details pd
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(cr.total_spent) AS city_spent,
    MIN(cr.total_spent) AS min_spent,
    MAX(cr.total_spent) AS max_spent
FROM customer_ranked cr
JOIN customer_address ca ON cr.c_customer_sk = ca.ca_address_sk
WHERE cr.rank = 1 AND cr.total_spent IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
ORDER BY city_spent DESC
LIMIT 10;
