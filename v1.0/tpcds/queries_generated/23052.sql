
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy = 10
        )
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(w.w_warehouse_name, 'Unknown Warehouse') AS warehouse_name,
        SUM(CASE WHEN ws.ws_quantity > 0 THEN ws.ws_quantity ELSE 0 END) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc, w.w_warehouse_name
), FilteredReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (
            SELECT MIN(d_date_sk)
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy IN (1, 10)
        )
    GROUP BY 
        sr_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.warehouse_name,
    COALESCE(rs.ws_order_number, 0) AS order_number,
    COALESCE(rs.ws_net_profit, 0) AS net_profit,
    COALESCE(fr.total_returned_quantity, 0) AS total_returned_quantity,
    id.total_sales_quantity,
    id.total_net_profit,
    CASE 
        WHEN id.total_net_profit IS NULL THEN 'No Sales'
        WHEN id.total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    ItemDetails id
LEFT JOIN 
    RankedSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.profit_rank = 1
LEFT JOIN 
    FilteredReturns fr ON id.i_item_sk = fr.sr_item_sk
WHERE 
    id.total_sales_quantity > (
        SELECT AVG(total_sales_quantity) 
        FROM ItemDetails
    ) AND 
    (id.total_net_profit IS NOT NULL OR id.total_net_profit <> 0)
ORDER BY 
    id.total_net_profit DESC, id.i_item_id;
