
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state
    FROM customer_address
    WHERE ca_state = 'CA'
    
    UNION ALL
    
    SELECT 
        a.ca_address_sk,
        a.ca_address_id,
        a.ca_street_name,
        a.ca_city,
        a.ca_state
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE a.ca_address_sk <> ah.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CombinedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_net_profit DESC) AS rank
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
),
AddressCount AS (
    SELECT
        COUNT(*) AS total_addresses,
        ca_state
    FROM customer_address
    GROUP BY ca_state
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    COUNT(DISTINCT cs.c_customer_sk) AS total_customers,
    ac.total_addresses,
    SUM(cs.c_birth_year) AS total_birth_years,
    AVG(fs.total_net_profit) AS avg_net_profit
FROM AddressHierarchy ah
LEFT JOIN customer cs ON cs.c_current_addr_sk = ah.ca_address_sk
JOIN CombinedSales fs ON fs.ws_sold_date_sk = (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
JOIN AddressCount ac ON ac.ca_state = ah.ca_state
WHERE cs.c_birth_year IS NOT NULL
GROUP BY ah.ca_city, ah.ca_state, ac.total_addresses
HAVING COUNT(DISTINCT cs.c_customer_sk) > 10
ORDER BY total_customers DESC;
