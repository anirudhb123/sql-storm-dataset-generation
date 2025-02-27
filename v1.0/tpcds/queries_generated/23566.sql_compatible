
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_sub.ws_sales_price) FROM web_sales ws_sub WHERE ws_sub.ws_item_sk = ws.ws_item_sk)
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.ws_net_profit,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY rs.ws_net_profit DESC) AS city_rank
    FROM 
        RankedSales rs
        JOIN customer_address ca ON rs.ws_item_sk = ca.ca_address_sk
)
SELECT 
    fs.ws_order_number,
    fs.ws_item_sk,
    fs.ws_sales_price,
    fs.ws_quantity,
    fs.ws_net_profit,
    fs.ca_city,
    fs.ca_state
FROM 
    FilteredSales fs
WHERE 
    fs.city_rank = 1
    AND (fs.ws_sales_price < COALESCE((SELECT MAX(ws_sub.ws_sales_price) FROM web_sales ws_sub WHERE ws_sub.ws_quantity = fs.ws_quantity), 0)
    OR fs.ws_net_profit IS NULL)
ORDER BY 
    fs.ca_state ASC,
    fs.ws_net_profit DESC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    ss.ss_order_number,
    ss.ss_item_sk,
    ss.ss_sales_price,
    ss.ss_quantity,
    ss.ss_net_profit,
    ca.ca_city,
    ca.ca_state
FROM 
    store_sales ss 
    LEFT JOIN customer_address ca ON ss.ss_customer_sk = ca.ca_address_sk
WHERE 
    ss.ss_sales_price IN (
        SELECT 
            DISTINCT(ws_sales_price)
        FROM 
            web_sales
        WHERE 
            ws_net_profit < 0
    )
    AND ca.ca_state IS NOT NULL
ORDER BY 
    ca.ca_city DESC
LIMIT 5;
