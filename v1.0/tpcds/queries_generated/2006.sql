
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        c.customer_id,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_profit > 0
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT tc.customer_id) AS total_customers,
    SUM(COALESCE(rs.ws_quantity, 0)) AS total_quantity_sold,
    AVG(tc.total_profit) AS avg_profit_per_customer
FROM top_customers tc
LEFT JOIN customer_address ca ON tc.customer_id = ca.ca_address_id
LEFT JOIN ranked_sales rs ON tc.customer_id = rs.ws_order_number
GROUP BY ca.ca_city
HAVING AVG(tc.total_profit) > 1000
ORDER BY total_quantity_sold DESC;
