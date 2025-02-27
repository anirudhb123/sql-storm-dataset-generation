
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_qty
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY sr_customer_sk
),
HighestReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_amount,
        cr.total_return_qty,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM CustomerReturns cr
    WHERE cr.return_count > 0
),
InventoryLevels AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(hr.return_count, 0) AS return_count,
    COALESCE(hr.total_return_amount, 0) AS total_return_amount,
    COALESCE(hr.total_return_qty, 0) AS total_return_qty,
    is_new_customer,
    CASE 
        WHEN hr.return_rank IS NOT NULL THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    rs.ws_item_sk,
    rs.ws_net_paid,
    COALESCE(il.total_stock, 0) AS stock_on_hand
FROM customer cs
LEFT JOIN HighestReturns hr ON cs.c_customer_sk = hr.sr_customer_sk
LEFT JOIN RankedSales rs ON rs.ws_order_number = (
        SELECT MIN(ws_order_number) 
        FROM web_sales 
        WHERE ws_item_sk IN (SELECT il.inv_item_sk FROM InventoryLevels il WHERE il.total_stock > 0)
        AND ws_bill_customer_sk = cs.c_customer_sk
        GROUP BY ws_item_sk
    )
LEFT JOIN InventoryLevels il ON il.inv_item_sk = rs.ws_item_sk
WHERE 
    (cs.c_birth_year = 1970 AND cs.c_city IS NOT NULL) 
    OR (cs.c_birth_year < 1970 AND cs.c_country IS NULL)
ORDER BY return_count DESC, cs.c_last_name ASC
FETCH FIRST 100 ROWS ONLY;
