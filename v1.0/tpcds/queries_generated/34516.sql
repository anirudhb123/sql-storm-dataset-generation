
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS trend_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(ws_sold_date_sk) - 30 FROM web_sales)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.order_count,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_stats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(cs.total_spent) AS total_revenue,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    MAX(st.total_quantity) AS max_monthly_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN top_customers cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN sales_trends st ON cs.c_customer_sk = st.ws_item_sk
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(cs.total_spent) > 1000
ORDER BY total_revenue DESC;
