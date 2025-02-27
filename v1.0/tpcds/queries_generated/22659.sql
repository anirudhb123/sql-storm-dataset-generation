
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_address_sk != ah.ca_address_sk
    WHERE ah.level < 5
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT ws_bill_customer_sk, total_profit, order_count
    FROM SalesSummary
    WHERE rn <= 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ah.ca_address_id,
    ah.ca_city,
    ah.ca_state,
    tc.total_profit,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.total_profit IS NULL THEN 'No Orders'
        WHEN tc.total_profit > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS value_segment,
    (SELECT COUNT(*) FROM store WHERE s_store_sk = ws_warehouse_sk) AS store_count
FROM customer c
LEFT JOIN AddressHierarchy ah ON c.c_current_addr_sk = ah.ca_address_sk
LEFT JOIN TopCustomers tc ON c.c_customer_sk = tc.ws_bill_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE (ah.ca_city LIKE 'San%' OR ah.ca_state = 'CA')
  AND (tc.order_count IS NULL OR tc.order_count > 0)
ORDER BY ah.ca_city, tc.total_profit DESC;
