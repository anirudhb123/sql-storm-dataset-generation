
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_tax DESC) AS rank_tax
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_ship > 100 
        AND ws.ws_ship_date_sk = (
            SELECT MAX(ws_inner.ws_ship_date_sk)
            FROM web_sales ws_inner
            WHERE ws_inner.ws_order_number = ws.ws_order_number
        )
)
, HighProfit AS (
    SELECT 
        ws_order_number,
        ws_net_profit 
    FROM 
        RankedSales 
    WHERE 
        rank_profit = 1
)
SELECT 
    ws_item_sk,
    SUM(CASE 
        WHEN ws_ext_sales_price IS NULL THEN 0 
        ELSE ws_ext_sales_price 
    END) AS total_sales,
    COALESCE(SUM(cs_ext_sales_price), 0) AS catalog_sales,
    COALESCE(SUM(ss_ext_sales_price), 0) AS store_sales,
    (SELECT COUNT(DISTINCT wr_refunded_customer_sk) 
     FROM web_returns wr 
     WHERE wr.wr_item_sk = ws_item_sk) AS web_return_count
FROM 
    web_sales ws
LEFT JOIN 
    catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND cs.cs_order_number IN (SELECT ws_order_number FROM HighProfit)
LEFT JOIN 
    store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ss.ss_ticket_number IN (SELECT ws_order_number FROM HighProfit)
WHERE 
    ws.ws_ship_date_sk > (SELECT MIN(d_date_sk) 
                           FROM date_dim 
                           WHERE d_year >= 2022 
                             AND d_month_seq BETWEEN 1 AND 12)
GROUP BY 
    ws_item_sk 
HAVING 
    SUM(ws_ext_sales_price) IS NOT NULL 
    OR total_sales > 0
ORDER BY 
    total_sales DESC 
LIMIT 10;
