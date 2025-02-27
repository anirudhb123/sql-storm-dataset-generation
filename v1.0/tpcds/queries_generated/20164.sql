
WITH RankedSales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS item_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_ship_tax > 100.00
        AND ws.ws_ship_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_dow NOT IN (1, 7)
        )
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        SUM(ri.ws_quantity) AS total_quantity_sold,
        SUM(ri.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales ri
    WHERE 
        ri.item_rank <= 10
    GROUP BY 
        ri.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ti.total_quantity_sold,
    ti.total_net_profit,
    (SELECT SUM(ws_ext_tax) 
     FROM web_sales 
     WHERE ws_item_sk = ti.ws_item_sk 
     AND ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023))
     AND (SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT MIN(d_month_seq) FROM date_dim WHERE d_year = 2023))) AS tax_in_current_year,
    (SELECT 
        CASE 
            WHEN COUNT(DISTINCT cr_call_center_sk) > 0 THEN 'Returns Available' 
            ELSE 'No Returns' 
        END 
     FROM catalog_returns cr 
     WHERE cr_item_sk = ti.ws_item_sk 
     AND cr_returned_date_sk <= ti.total_quantity_sold) AS return_status
FROM 
    item i
JOIN 
    TopItems ti ON i.i_item_sk = ti.ws_item_sk
LEFT JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
FULL OUTER JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    (s.s_country = 'USA' OR s.s_country IS NULL)
    AND s.s_division_id IS NOT NULL
ORDER BY 
    ti.total_net_profit DESC
LIMIT 50;
