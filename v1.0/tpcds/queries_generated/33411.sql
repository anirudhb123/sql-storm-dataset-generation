
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, c_birth_country, 1 AS level
    FROM customer
    WHERE c_birth_country IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, c.c_birth_country, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_birth_country IS NOT NULL
),

SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sales_price > 0
    GROUP BY ws.web_site_sk
),

AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(c.c_customer_sk) AS city_customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
),

Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_dep_count) AS avg_dependents,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk
)

SELECT 
    ad.ca_city,
    SUM(sd.total_net_profit) AS city_total_net_profit,
    AVG(demo.avg_dependents) AS average_dependents,
    COUNT(DISTINCT cust.c_customer_sk) AS total_customers
FROM AddressInfo ad
LEFT JOIN SalesData sd ON ad.city_customer_count > 0
LEFT JOIN Demographics demo ON ad.city_customer_count > 0
LEFT JOIN customer cust ON ad.city_customer_count > 0
GROUP BY ad.ca_city
HAVING COUNT(DISTINCT cust.c_customer_sk) > 0
ORDER BY city_total_net_profit DESC
LIMIT 10;
