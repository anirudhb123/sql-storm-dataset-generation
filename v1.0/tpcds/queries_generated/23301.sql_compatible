
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity_sold
    FROM web_sales
), calculated_returns AS (
    SELECT 
        ws.ws_item_sk,
        SUM(CASE 
            WHEN wr_refunded_cash IS NOT NULL THEN wr_refunded_cash 
            ELSE 0 
        END) AS total_refunded_cash,
        COUNT(DISTINCT wr_order_number) AS total_refunds
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    GROUP BY ws.ws_item_sk
), outer_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        COALESCE(cr.total_refunded_cash, 0) AS total_refunded_cash,
        COALESCE(cr.total_refunds, 0) AS total_refunds
    FROM ranked_sales r
    LEFT JOIN calculated_returns cr ON r.ws_item_sk = cr.ws_item_sk
)
SELECT 
    os.ws_item_sk,
    os.ws_sales_price,
    os.total_refunded_cash,
    os.total_refunds,
    os.ws_sales_price - os.total_refunded_cash AS net_sales,
    CASE 
        WHEN os.total_refunds > 0 THEN 'Refunded'
        ELSE 'Not Refunded'
    END AS refund_status,
    STRING_AGG(CASE 
        WHEN ot.d_dow IS NOT NULL THEN CONCAT('Sold on ', ot.d_day_name) 
        ELSE 'Sale Date Unknown' 
    END, ', ') AS sale_dates
FROM outer_sales os
JOIN date_dim d ON d.d_date_sk = os.ws_sales_price % 100
LEFT JOIN date_dim ot ON ot.d_date_sk = (SELECT t_time_sk FROM time_dim WHERE t_hour % 2 = 0 LIMIT 1)
WHERE os.ws_sales_price IS NOT NULL
GROUP BY os.ws_item_sk, os.ws_sales_price, os.total_refunded_cash, os.total_refunds
HAVING (os.ws_sales_price - os.total_refunded_cash) > 0 OR 
       (CASE 
            WHEN os.total_refunds > 0 THEN 'Refunded'
            ELSE 'Not Refunded'
        END) = 'Refunded'
ORDER BY net_sales DESC
LIMIT 50;
