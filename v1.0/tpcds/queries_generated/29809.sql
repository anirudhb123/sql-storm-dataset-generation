
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
CustomerAnalytics AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        CONCAT(a.full_address, ', ', a.ca_city, ', ', a.ca_state) AS complete_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
),
PurchaseStats AS (
    SELECT 
        ca_address_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM web_sales
    GROUP BY ca_address_sk
),
FinalReport AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        ca.city,
        ca.state,
        COALESCE(ps.total_orders, 0) AS orders_count,
        COALESCE(ps.total_spent, 0.00) AS total_spent
    FROM AddressDetails ca
    LEFT JOIN PurchaseStats ps ON ca.ca_address_sk = ps.ca_address_sk
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY orders_count DESC, total_spent DESC) AS rank,
    full_address,
    city,
    state,
    orders_count,
    total_spent
FROM FinalReport
WHERE total_spent > 0
ORDER BY orders_count DESC, total_spent DESC;
