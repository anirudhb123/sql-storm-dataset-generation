
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_returns,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_store_returns,
    CASE WHEN COUNT(DISTINCT w.w_warehouse_id) > 0 THEN 'Exists' ELSE 'No Warehouses' END AS warehouse_status
FROM 
    ranked_sales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
LEFT JOIN 
    catalog_returns cr ON i.i_item_sk = cr.cr_item_sk AND cr.cr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
LEFT JOIN 
    store_returns sr ON i.i_item_sk = sr.sr_item_sk AND sr.sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
LEFT JOIN 
    inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    rs.rank = 1
GROUP BY 
    i.i_item_id, i.i_item_desc
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_store_quantity DESC
LIMIT 10;
