
WITH RECURSIVE ItemSales AS (
    SELECT 
        ws_item_sk, 
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
),
HighProfitItems AS (
    SELECT 
        IS.ws_item_sk,
        SUM(IS.ws_net_profit) AS total_net_profit,
        COUNT(IS.ws_quantity) AS total_sales
    FROM ItemSales IS
    WHERE IS.rnk <= 10
    GROUP BY IS.ws_item_sk
),
AddressInfo AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_state,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(c.c_customer_sk) DESC) AS rnk
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_state, ca.ca_city
)
SELECT 
    hi.ws_item_sk,
    hi.total_net_profit,
    hi.total_sales,
    ad.ca_state,
    ad.ca_city
FROM HighProfitItems hi
JOIN AddressInfo ad ON hi.ws_item_sk = ad.c_customer_sk
WHERE ad.rnk = 1
ORDER BY hi.total_net_profit DESC
LIMIT 10;
