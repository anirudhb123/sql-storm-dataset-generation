
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_prod
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2452007 AND 2452500
),
total_sales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),
average_sales AS (
    SELECT 
        AVG(total_profit) AS avg_profit
    FROM total_sales
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS customer_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING COUNT(ws.ws_order_number) > 5
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT 
    tc.order_count,
    tc.customer_profit,
    ai.city,
    ai.state,
    ai.customer_count,
    rs.ws_item_sk,
    rs.rank_prod,
    ts.total_profit,
    (SELECT * FROM average_sales) AS avg_profit
FROM top_customers tc
JOIN address_info ai ON tc.c_customer_id IS NOT NULL
LEFT JOIN ranked_sales rs ON tc.order_count > rs.rank_prod
LEFT JOIN total_sales ts ON ts.ws_order_number = rs.ws_order_number
WHERE tc.customer_profit > (SELECT avg_profit FROM average_sales)
ORDER BY tc.customer_profit DESC, ai.customer_count DESC;
