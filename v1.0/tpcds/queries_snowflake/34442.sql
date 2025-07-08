
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           0 AS level
    FROM customer c
    WHERE c.c_birth_year >= 1980
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459810 AND 2459850
    GROUP BY ws_ship_mode_sk
),
AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
CustomerSales AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ad.full_address,
        sd.total_quantity,
        sd.avg_net_profit
    FROM CustomerHierarchy ch
    LEFT JOIN AddressDetails ad ON ch.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON sd.ws_ship_mode_sk = (
        SELECT sm_ship_mode_sk FROM ship_mode
        WHERE sm_type = 'AIR')
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.full_address,
    COALESCE(cs.total_quantity, 0) AS total_quantity,
    COALESCE(cs.avg_net_profit, 0) AS avg_net_profit,
    DENSE_RANK() OVER (ORDER BY COALESCE(cs.avg_net_profit, 0) DESC) AS profit_rank
FROM CustomerSales cs
WHERE cs.avg_net_profit IS NOT NULL
ORDER BY profit_rank
FETCH FIRST 10 ROWS ONLY;
