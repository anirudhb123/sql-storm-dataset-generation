
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, NULL AS parent_customer_sk
    FROM customer c
    WHERE c.c_customer_sk < 100  -- Top-level customers
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.c_customer_sk
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(sd.total_net_paid) AS total_sales
    FROM item i
    JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
    HAVING SUM(sd.total_net_paid) > 1000  -- Filter for popular items
),
ShippingModes AS (
    SELECT DISTINCT sm.sm_ship_mode_id, sm.sm_type
    FROM ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS returns_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
    bsi.i_item_id,
    bsi.i_item_desc,
    bsi.total_sales,
    sm.sm_type AS shipping_method,
    NULLIF(cr.returns_count, 0) AS returns_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount
FROM CustomerHierarchy ch
JOIN BestSellingItems bsi ON bsi.total_sales IS NOT NULL
JOIN ShippingModes sm ON sm.sm_ship_mode_id = 'SHIP1'  -- Filter for specific shipping mode
LEFT JOIN CustomerReturns cr ON cr.cr_item_sk = bsi.i_item_id
ORDER BY bsi.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
