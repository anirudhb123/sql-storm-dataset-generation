
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100
),
ItemInfo AS (
    SELECT 
        i.i_item_id,
        i.i_current_price,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        COALESCE(NULLIF(CAST(AVG(rs.ws_net_profit) AS DECIMAL(10, 2)), 0), CAST(1 AS DECIMAL(10, 2))) AS avg_net_profit
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_current_price, i.i_item_desc, i.i_category, i.i_brand
),
SalesSummary AS (
    SELECT 
        ii.i_item_id,
        ii.i_current_price,
        ii.i_item_desc,
        COALESCE(NULLIF(ii.avg_net_profit, 0), MIN(ii.i_current_price)) - 0.1 AS adjusted_profit,
        CASE 
            WHEN ii.i_current_price < 10 THEN 'Low'
            WHEN ii.i_current_price BETWEEN 10 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS price_category
    FROM 
        ItemInfo ii
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.adjusted_profit,
    ss.price_category,
    COUNT(NULLIF(ws.ws_item_sk, rs.ws_item_sk)) AS unmatched_sales_count,
    SUM(ws.ws_quantity) FILTER (WHERE ws.ws_ship_mode_sk IS NULL) AS null_ship_mode_sales
FROM 
    SalesSummary ss
LEFT JOIN 
    web_sales ws ON ss.i_item_id = ws.ws_item_sk
LEFT JOIN 
    RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk AND rs.rank = 1
GROUP BY 
    ss.i_item_id, ss.i_item_desc, ss.adjusted_profit, ss.price_category
HAVING 
    SUM(ws.ws_quantity) > (SELECT AVG(ws2.ws_quantity) FROM web_sales ws2 WHERE ws2.ws_item_sk = ss.i_item_id)
ORDER BY 
    ss.adjusted_profit DESC, price_category
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
