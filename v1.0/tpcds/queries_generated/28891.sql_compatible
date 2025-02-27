
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_profit,
        si.order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COALESCE(total_profit, 0) AS total_profit,
    COALESCE(order_count, 0) AS order_count,
    CASE 
        WHEN total_profit IS NULL THEN 'No Sales'
        WHEN total_profit > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_category
FROM CombinedInfo
ORDER BY total_profit DESC, full_name;
