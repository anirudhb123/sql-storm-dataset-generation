
WITH last_month_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10)
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        ls.total_sales, 
        ls.total_profit,
        DENSE_RANK() OVER (ORDER BY ls.total_sales DESC) AS sales_rank
    FROM last_month_sales ls
    JOIN item i ON ls.ws_item_sk = i.i_item_sk
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_profit,
    COALESCE(SM.sm_type, 'Standard') AS shipping_mode,
    CASE 
        WHEN ti.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM top_items ti
LEFT JOIN (
    SELECT 
        cs_item_sk, 
        sm_ship_mode_sk 
    FROM catalog_sales 
    LEFT JOIN ship_mode ON cs_ship_mode_sk = sm_ship_mode_sk
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10)
) cs ON cs.cs_item_sk = ti.ws_item_sk
JOIN ship_mode SM ON cs.sm_ship_mode_sk = SM.sm_ship_mode_sk
WHERE ti.total_sales IS NOT NULL
ORDER BY ti.total_sales DESC;
