
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rnk
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
),
top_stores AS (
    SELECT 
        ss_store_sk,
        SUM(total_quantity) AS total_store_quantity,
        SUM(total_sales) AS total_store_sales
    FROM 
        sales_summary
    WHERE 
        rnk <= 5
    GROUP BY 
        ss_store_sk
)
SELECT 
    s.s_store_id,
    SUM(ws.net_profit) AS total_web_profit,
    COALESCE(ts.total_store_sales, 0) AS store_sales,
    (SUM(ws.net_profit) - COALESCE(ts.total_store_sales, 0)) AS profit_after_store_sales
FROM 
    web_sales ws
LEFT JOIN 
    top_stores ts ON ws.ws_ship_addr_sk = ts.ss_store_sk
LEFT JOIN 
    store s ON ts.ss_store_sk = s.s_store_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    s.s_store_id, ts.total_store_sales
HAVING 
    SUM(ws.net_profit) > 1000
ORDER BY 
    total_web_profit DESC
LIMIT 10;
