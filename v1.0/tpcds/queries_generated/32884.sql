
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 4
), SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), HighSpender AS (
    SELECT
        s.customer_id,
        s.total_spent,
        s.total_orders
    FROM SalesSummary s
    WHERE s.total_spent > (SELECT AVG(total_spent) FROM SalesSummary)
), AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ad.full_address,
    hs.total_spent,
    hs.total_orders,
    ROW_NUMBER() OVER (PARTITION BY ad.full_address ORDER BY hs.total_spent DESC) AS rank
FROM CustomerHierarchy ch
LEFT JOIN HighSpender hs ON ch.c_customer_sk = hs.customer_id
LEFT JOIN AddressDetails ad ON ch.c_current_addr_sk = ad.ca_address_sk
WHERE hs.total_orders IS NOT NULL
ORDER BY hs.total_spent DESC, ch.c_last_name ASC
LIMIT 100;
