
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        SUM(CASE WHEN ca_country IS NULL THEN 1 ELSE 0 END) AS null_country_count
    FROM customer_address
    GROUP BY ca_state
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.level,
    sa.total_sales,
    sa.order_count,
    ad.address_count,
    ad.null_country_count
FROM CustomerHierarchy ch
LEFT JOIN SalesData sa ON ch.c_current_addr_sk = sa.ws_item_sk
LEFT JOIN AddressStats ad ON ad.ca_state = (
    SELECT ca_state 
    FROM customer_address 
    WHERE ca_address_sk = ch.c_current_addr_sk
)
WHERE ch.level < 3
ORDER BY ch.level, sa.total_sales DESC NULLS LAST;
