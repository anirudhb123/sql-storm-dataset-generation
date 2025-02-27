
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_current_price,
        inv.inv_quantity_on_hand
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
FinalResults AS (
    SELECT 
        it.i_item_id,
        it.i_product_name,
        it.i_brand,
        it.i_current_price,
        sd.ws_order_number,
        sd.ws_net_paid,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.return_count, 0) AS return_count
    FROM 
        ItemDetails it
    LEFT JOIN 
        SalesData sd ON it.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.sr_returned_date_sk = sd.ws_ship_date_sk
    WHERE 
        sd.rn = 1
)
SELECT 
    *,
    CASE 
        WHEN total_return_amount > 0 THEN 'High Return'
        WHEN ws_net_paid IS NULL THEN 'No Sales'
        ELSE 'Normal'
    END AS sales_status
FROM 
    FinalResults
WHERE 
    (total_return_amount > 0 OR ws_net_paid IS NOT NULL)
ORDER BY 
    (total_return_amount - (ws_net_paid * 0.10)) DESC
LIMIT 100;
