
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', 
               ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY ca.ca_city) AS address_rank
    FROM customer_address ca
)
SELECT 
    ch.c_customer_sk, 
    ch.c_first_name,
    ch.c_last_name,
    ad.full_address,
    ad.ca_country,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CustomerHierarchy ch
LEFT JOIN AddressDetails ad ON ch.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
WHERE ad.address_rank <= 5
ORDER BY ch.c_last_name, ch.c_first_name;
