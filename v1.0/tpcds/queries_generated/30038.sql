
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
filtered_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        s.total_profit,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN s.total_profit IS NULL THEN 'No Profit Data'
            ELSE CONCAT('Profit: ', CAST(s.total_profit AS VARCHAR))
        END AS profit_info
    FROM 
        sales_summary s
    LEFT JOIN customer_address ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk 
        FROM customer c 
        WHERE c.c_customer_sk IN (
            SELECT DISTINCT ws_ship_customer_sk 
            FROM web_sales 
            WHERE ws_item_sk = s.ws_item_sk
        )
        LIMIT 1
    )
    WHERE s.rank = 1
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_profit,
    f.ca_city,
    f.ca_state,
    f.ca_country,
    f.profit_info
FROM 
    filtered_sales f
ORDER BY 
    f.total_sales DESC
LIMIT 100;
