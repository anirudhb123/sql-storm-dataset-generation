
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_hdemo_sk IS NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
AddressCounts AS (
    SELECT 
        ca.ca_country,
        COUNT(c.c_current_addr_sk) AS address_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_country
),
FinalReport AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_profit, 0) AS total_profit,
        ac.address_count
    FROM CustomerHierarchy ch
    LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.c_customer_sk
    LEFT JOIN AddressCounts ac ON ch.c_current_addr_sk = ac.address_count
    WHERE (ss.total_profit > 1000 OR ss.total_orders > 5 OR ac.address_count IS NOT NULL)
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_orders,
    f.total_profit,
    f.address_count,
    ROW_NUMBER() OVER (PARTITION BY f.c_customer_sk ORDER BY f.total_profit DESC) AS rank
FROM FinalReport f
WHERE f.total_profit IS NOT NULL
ORDER BY f.total_profit DESC;
