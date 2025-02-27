
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price 
    FROM item 
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price 
    FROM item i
    INNER JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
), 
ReturnAnalysis AS (
    SELECT 
        sr_item_sk AS item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        SUM(ws.ws_coupon_amt) AS total_coupons_applied
    FROM web_sales ws 
    GROUP BY ws.ws_item_sk
),
JoinedData AS (
    SELECT 
        ih.i_item_id,
        ih.i_item_desc,
        COALESCE(sa.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sa.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(ra.total_returns, 0) AS total_returns,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        sa.total_coupons_applied
    FROM ItemHierarchy ih
    LEFT JOIN SalesData sa ON ih.i_item_sk = sa.ws_item_sk
    LEFT JOIN ReturnAnalysis ra ON ih.i_item_sk = ra.item_sk
)
SELECT 
    jd.i_item_id,
    jd.i_item_desc,
    jd.total_quantity_sold,
    jd.total_sales_amount,
    jd.total_returns,
    jd.total_return_amount,
    jd.total_coupons_applied,
    (CASE 
        WHEN jd.total_quantity_sold > 0 THEN (jd.total_return_amount / jd.total_sales_amount) * 100 
        ELSE NULL 
    END) AS returns_percentage,
    (CASE 
        WHEN jd.total_sales_amount > 0 AND jd.total_coupons_applied > 0 
        THEN (jd.total_coupons_applied / jd.total_sales_amount) * 100 
        ELSE 0 
    END) AS coupon_percentage
FROM JoinedData jd
WHERE (jd.total_sales_amount > 100 OR jd.total_returns > 10)
ORDER BY returns_percentage DESC, total_sales_amount DESC
LIMIT 50;
