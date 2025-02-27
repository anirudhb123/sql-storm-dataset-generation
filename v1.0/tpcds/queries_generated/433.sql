
WITH RankedSales AS (
    SELECT 
        w.warehouse_name,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales 
    JOIN 
        warehouse w ON ws_warehouse_sk = w.warehouse_sk
    GROUP BY 
        w.warehouse_name, ws_item_sk
), 
ItemReasons AS (
    SELECT 
        wr_item_sk, 
        COUNT(DISTINCT wr_reason_sk) AS reason_count
    FROM 
        web_returns 
    WHERE 
        wr_return_quantity > 0
    GROUP BY 
        wr_item_sk
), 
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_net_paid
    FROM 
        RankedSales
    WHERE 
        rank_sales <= 5
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_net_paid,
    COALESCE(ir.reason_count, 0) AS return_reason_count,
    CASE 
        WHEN COALESCE(ir.reason_count, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    TopItems ti 
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    ItemReasons ir ON ti.ws_item_sk = ir.wr_item_sk
WHERE 
    ti.total_net_paid > 1000 AND 
    EXISTS (
        SELECT 1 
        FROM store_sales s 
        WHERE s.ss_item_sk = ti.ws_item_sk AND s.ss_net_paid < 50
    )
ORDER BY 
    ti.total_net_paid DESC;
