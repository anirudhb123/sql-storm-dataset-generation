
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
), ReturnDetails AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returned,
        COUNT(DISTINCT rr.sr_ticket_number) AS return_count,
        MAX(rr.sr_returned_date_sk) AS last_return_date
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn <= 5
    GROUP BY 
        rr.sr_item_sk
), InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        MAX(inv.inv_date_sk) AS last_inventory_date
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
), SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
), ItemMetrics AS (
    SELECT 
        i.i_item_sk,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(invs.total_quantity_on_hand, 0) AS total_quantity_on_hand,
        COALESCE(ss.total_sold, 0) AS total_sold,
        COALESCE(ss.avg_sales_price, 0) AS avg_sales_price,
        CASE 
            WHEN COALESCE(ss.total_sold, 0) = 0 THEN NULL 
            ELSE COALESCE(rs.total_returned, 0) / NULLIF(COALESCE(ss.total_sold, 0), 0) 
        END AS return_rate
    FROM 
        item i
    LEFT JOIN 
        ReturnDetails rs ON i.i_item_sk = rs.sr_item_sk
    LEFT JOIN 
        InventoryStatus invs ON i.i_item_sk = invs.inv_item_sk
    LEFT JOIN 
        SalesSummary ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    im.i_item_sk,
    im.total_returned,
    im.total_quantity_on_hand,
    im.total_sold,
    im.avg_sales_price,
    im.return_rate,
    CASE 
        WHEN im.return_rate IS NULL THEN 'No sales'
        WHEN im.return_rate > 0.5 THEN 'High return rate'
        ELSE 'Normal return rate'
    END AS return_status
FROM 
    ItemMetrics im
WHERE 
    im.total_sold > 10
ORDER BY 
    im.return_rate DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
