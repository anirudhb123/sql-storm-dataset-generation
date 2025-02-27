
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2405
    GROUP BY 
        ws.web_site_id, ws.ws_item_sk
), FilteredSales AS (
    SELECT 
        rs.web_site_id,
        rs.ws_item_sk,
        rs.total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
), LowStockItems AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = 2404
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) < 5
), TopReasons AS (
    SELECT 
        r.r_reason_desc,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
    ORDER BY 
        return_count DESC
    LIMIT 5
)
SELECT 
    f.web_site_id,
    i.i_item_id,
    COALESCE(ls.total_on_hand, 0) AS stock_level,
    COALESCE(tr.return_count, 0) AS return_frequency
FROM 
    FilteredSales f
LEFT JOIN 
    item i ON f.ws_item_sk = i.i_item_sk
LEFT JOIN 
    LowStockItems ls ON f.ws_item_sk = ls.inv_item_sk
LEFT JOIN 
    (SELECT 
        rt.r_reason_desc, rt.return_count,
        ROW_NUMBER() OVER (ORDER BY rt.return_count DESC) AS rn
     FROM 
        TopReasons rt
    ) tr ON tr.rn = 1 -- Just to get the top reason for returns
WHERE 
    i.i_current_price IS NOT NULL
    AND (f.total_quantity IS NOT NULL OR f.total_quantity <> 0)
ORDER BY 
    f.web_site_id, stock_level DESC, return_frequency DESC;
