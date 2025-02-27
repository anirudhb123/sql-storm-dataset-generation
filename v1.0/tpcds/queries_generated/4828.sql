
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price BETWEEN 10 AND 100
    GROUP BY ws.ws_item_sk, ws.ws_order_number, ws.ws_sold_date_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    cs.total_orders,
    cs.total_spent,
    cs.avg_profit,
    COALESCE(rs.total_net_profit, 0) AS best_net_profit_item
FROM customer_address ca
LEFT JOIN customer_sales cs ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN ranked_sales rs ON rs.ws_item_sk IN (
    SELECT i.i_item_sk 
    FROM item i 
    WHERE i.i_current_price = (
        SELECT MAX(i2.i_current_price) 
        FROM item i2
        WHERE i2.i_item_sk = rs.ws_item_sk
    )
) AND rs.rn = 1
WHERE ca.ca_state IS NOT NULL
ORDER BY cs.total_spent DESC, ca.ca_city;
