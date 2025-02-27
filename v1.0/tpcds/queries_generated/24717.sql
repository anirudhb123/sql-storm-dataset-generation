
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
Refunds AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemAnalysis AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(r.total_returned, 0) AS total_returned,
        COALESCE(sd.order_count, 0) AS order_count,
        (COALESCE(sd.total_sales, 0) - COALESCE(r.total_returned, 0)) AS net_sales,
        CASE 
            WHEN COALESCE(sd.order_count, 0) > 0 THEN ROUND((COALESCE(r.return_count, 0) * 100.0) / COALESCE(sd.order_count, 0), 2)
            ELSE NULL 
        END AS return_rate
    FROM 
        item AS i
    LEFT JOIN 
        SalesData AS sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        Refunds AS r ON i.i_item_sk = r.sr_item_sk
)
SELECT 
    ia.i_item_sk,
    ia.i_item_desc,
    ia.total_sales,
    ia.total_returned,
    ia.net_sales,
    ia.return_rate,
    CASE 
        WHEN ia.return_rate IS NULL THEN 'No orders'
        WHEN ia.return_rate > 50 THEN 'High Return Rate'
        WHEN ia.return_rate BETWEEN 20 AND 50 THEN 'Moderate Return Rate'
        ELSE 'Acceptable Return Rate'
    END AS return_rate_category
FROM 
    ItemAnalysis AS ia
LEFT JOIN 
    warehouse AS w ON EXISTS (
        SELECT 1 FROM inventory inv 
        WHERE inv.inv_item_sk = ia.i_item_sk 
            AND inv.inv_quantity_on_hand > 0 
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
    )
WHERE 
    (ia.total_sales > 5000 OR ia.total_returned > 200)
    AND (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) > 8000
ORDER BY 
    ia.return_rate DESC, ia.net_sales DESC;
