
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS avg_net_profit,
        STRING_AGG(DISTINCT w.web_name, ', ') AS web_names
    FROM 
        web_sales ws 
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND CURRENT_DATE)
    GROUP BY 
        ws.web_site_sk, ws.ws_item_sk
),
FilteredSales AS (
    SELECT 
        rs.*, 
        CASE 
            WHEN rs.total_quantity > 100 THEN 'High Volume' 
            WHEN rs.total_quantity IS NULL THEN 'No Sales'
            ELSE 'Low Volume' 
        END AS volume_category
    FROM 
        RankedSales rs
),
FinalResults AS (
    SELECT 
        fs.web_site_sk,
        fs.ws_item_sk, 
        fs.total_quantity,
        fs.order_count,
        fs.avg_net_profit,
        fs.volume_category,
        RANK() OVER (PARTITION BY fs.web_site_sk ORDER BY fs.avg_net_profit DESC) AS rank_by_profit
    FROM 
        FilteredSales fs
)
SELECT 
    fw.web_site_sk,
    fw.ws_item_sk,
    fw.total_quantity,
    fw.order_count,
    fw.avg_net_profit,
    fw.volume_category,
    fw.rank_by_profit,
    COALESCE(inventory.inv_quantity_on_hand, 0) AS inventory_on_hand
FROM 
    FinalResults fw
LEFT JOIN inventory ON fw.ws_item_sk = inventory.inv_item_sk
AND (
    (inventory.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory) 
    AND inventory.inv_warehouse_sk IN (SELECT w.warehouse_sk FROM warehouse w WHERE w.w_cust_direction IS NULL)) 
    OR inventory.inv_warehouse_sk IS NULL
)
ORDER BY 
    fw.web_site_sk, fw.rank_by_profit;
