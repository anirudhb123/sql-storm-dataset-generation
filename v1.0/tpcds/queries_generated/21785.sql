
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price > 0
),
refunds AS (
    SELECT 
        vr_item_sk,
        vr_order_number,
        vr_refunded_cash,
        vr_return_quantity
    FROM web_returns
)
SELECT 
    ca.ca_address_id,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(r.refunded_cash) AS total_refund,
    AVG(ws.net_profit) AS avg_profit_per_order
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN ranked_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN refunds r ON ws.ws_item_sk = r.vr_item_sk AND ws.ws_order_number = r.vr_order_number
WHERE 
    ca.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'CA' AND ca_zip IS NOT NULL)
    AND (c.c_birth_year < 1970 OR c.c_birth_year IS NULL)
GROUP BY ca.ca_address_id
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY total_refund DESC
FETCH FIRST 10 ROWS ONLY;
