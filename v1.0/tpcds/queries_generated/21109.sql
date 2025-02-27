
WITH RECURSIVE AddressTree AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, at.level + 1
    FROM customer_address a
    JOIN AddressTree at ON a.ca_state = at.ca_state
    WHERE a.ca_city IS NOT NULL AND at.level < 3
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_spent DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender
),
HighSpendCustomers AS (
    SELECT *
    FROM CustomerMetrics
    WHERE total_spent > (SELECT AVG(total_spent) FROM CustomerMetrics) 
)
SELECT at.ca_city, 
       at.ca_state, 
       at.ca_country, 
       COALESCE(hs.total_orders, 0) AS orders_count, 
       COALESCE(hs.total_spent, 0) AS spending,
       CASE 
           WHEN hs.gender_rank IS NULL THEN 'Not Ranked'
           ELSE 'Ranked'
       END AS rank_status,
       STRING_AGG(CONCAT(hs.c_first_name, ' ', hs.c_last_name), ', ') AS customer_names
FROM AddressTree at
LEFT JOIN HighSpendCustomers hs ON 
    (CASE 
        WHEN at.ca_country = 'USA' THEN 
            (SELECT COUNT(*) FROM customer_address WHERE ca_city = at.ca_city AND ca_state = at.ca_state)  
        ELSE 
            0 
     END) > 0 
GROUP BY at.ca_city, at.ca_state, at.ca_country
ORDER BY spending DESC NULLS LAST
LIMIT 10;
