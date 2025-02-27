
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, cc.level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_current_addr_sk = cc.c_current_addr_sk
    WHERE cc.level < 3
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
AddressSales AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
)
SELECT 
    cte.c_first_name || ' ' || cte.c_last_name AS full_name,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_profit, 0.00) AS total_profit,
    COALESCE(as.total_profit, 0.00) AS address_total_profit,
    CASE 
        WHEN as.order_count IS NULL THEN 'No sales'
        ELSE 'Has sales'
    END AS sales_status
FROM CustomerCTE cte
LEFT JOIN SalesSummary ss ON cte.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN AddressSales as ON cte.c_current_addr_sk = as.ca_address_sk
WHERE cte.level = 1
ORDER BY total_profit DESC
LIMIT 10;
