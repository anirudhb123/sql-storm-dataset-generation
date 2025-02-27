
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sold,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY cs_item_sk
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        COALESCE(sd.total_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_profit, 0) AS total_net_profit,
        item.i_current_price,
        item.i_category,
        RANK() OVER (PARTITION BY item.i_category ORDER BY COALESCE(sd.total_profit, 0) DESC) AS profit_rank
    FROM item
    LEFT JOIN sales_data sd ON item.i_item_sk = sd.ws_item_sk OR item.i_item_sk = sd.cs_item_sk
)
SELECT 
    a.i_item_id,
    a.total_quantity_sold,
    a.total_net_profit,
    a.i_current_price,
    a.i_category
FROM aggregated_sales a
WHERE a.profit_rank <= 10
ORDER BY a.i_category, a.total_net_profit DESC
LIMIT 100;

SELECT DISTINCT
    w.w_warehouse_id,
    SUM(COALESCE(ss.ss_quantity, 0)) AS total_store_sales,
    SUM(COALESCE(ws.ws_quantity, 0)) AS total_web_sales
FROM warehouse w
LEFT JOIN store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
WHERE w.w_country IS NOT NULL
GROUP BY w.w_warehouse_id
HAVING total_store_sales > 500 OR total_web_sales > 1000;
