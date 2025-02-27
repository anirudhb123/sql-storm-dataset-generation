
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        item.i_current_price,
        item.i_class,
        ss.total_quantity,
        ss.total_profit 
    FROM 
        item
    JOIN 
        SalesSummary ss ON item.i_item_sk = ss.ws_item_sk
    WHERE 
        ss.rnk <= 10
)
SELECT 
    ta.i_item_sk, 
    ta.i_product_name, 
    ta.i_current_price, 
    COALESCE(ta.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ta.total_profit, 0) AS total_net_profit,
    (SELECT COUNT(DISTINCT wr_return_id) FROM web_returns wr WHERE wr.wr_item_sk = ta.i_item_sk) AS total_returns,
    (SELECT AVG(ws_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = ta.i_item_sk) AS avg_sales_price,
    CASE 
        WHEN ta.total_profit IS NULL THEN 'No Sales'
        WHEN ta.total_profit >= 1000 THEN 'High Performer'
        ELSE 'Moderate Performer'
    END AS performance_category
FROM 
    TopItems ta
LEFT JOIN 
    catalog_returns cr ON ta.i_item_sk = cr.cr_item_sk
FULL OUTER JOIN 
    store_sales ss ON ta.i_item_sk = ss.ss_item_sk
WHERE 
    ta.total_quantity > 0 
    AND (ta.i_class LIKE 'Electronics%' OR ta.i_class LIKE 'Clothing%')
ORDER BY 
    ta.total_profit DESC, 
    total_quantity_sold DESC;
