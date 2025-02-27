
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
RecentOrderSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
CombinedInformation AS (
    SELECT 
        i.i_item_id,
        inv.inv_quantity_on_hand,
        COALESCE(RR.sr_return_quantity, 0) AS total_returns,
        COALESCE(RO.total_sold, 0) AS total_sales,
        (inv.inv_quantity_on_hand - COALESCE(RR.sr_return_quantity, 0)) AS available_stock,
        CASE 
            WHEN (inv.inv_quantity_on_hand - COALESCE(RR.sr_return_quantity, 0)) < 0 THEN 'Negative Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        item i
    LEFT JOIN 
        (SELECT *
         FROM RankedReturns
         WHERE rn = 1) RR ON i.i_item_sk = RR.sr_item_sk
    LEFT JOIN 
        RecentOrderSales RO ON i.i_item_sk = RO.ws_item_sk
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
)
SELECT 
    ci.i_item_id,
    ci.inv_quantity_on_hand,
    ci.total_returns,
    ci.total_sales,
    ci.available_stock,
    ci.stock_status,
    STRING_AGG(CASE 
                   WHEN ci.stock_status = 'Negative Stock' THEN 'Alert! Stock Negative'
                   ELSE NULL 
               END, '; ') AS alerts
FROM 
    CombinedInformation ci
WHERE 
    ci.available_stock < 50 
    OR (ci.total_sales = 0 AND ci.total_returns = 0)
GROUP BY 
    ci.i_item_id, ci.inv_quantity_on_hand, ci.total_returns, ci.total_sales, ci.available_stock, ci.stock_status
ORDER BY 
    ci.available_stock ASC, ci.total_sales DESC;
