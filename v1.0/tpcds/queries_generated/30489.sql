
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
), SalesSummary AS (
    SELECT 
        cs.cs_item_sk, 
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS unique_orders
    FROM catalog_sales cs 
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL AND i.i_current_price > 0
    GROUP BY cs.cs_item_sk
), AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ' ', ca.ca_state) AS full_address
    FROM customer_address ca
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ad.full_address,
    ss.total_quantity_sold,
    ss.total_net_profit
FROM CustomerHierarchy ch
LEFT JOIN AddressDetails ad ON ch.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN SalesSummary ss ON ss.cs_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns)
WHERE ss.total_net_profit IS NOT NULL
ORDER BY ss.total_net_profit DESC
LIMIT 50;
