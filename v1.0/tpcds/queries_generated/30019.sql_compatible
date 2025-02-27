
WITH RECURSIVE ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM web_sales
    WHERE ws_quantity > 0
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM date_dim d
    JOIN ranked_sales rs ON d.d_date_sk = rs.ws_sold_date_sk
    WHERE d.d_year = 2023
    AND rs.sales_rank = 1
    GROUP BY d.d_date
),
customer_return_stats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ds.d_date,
    ds.total_quantity AS total_sales_quantity,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    ds.total_sales AS total_sales_amount,
    (ds.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales,
    CASE 
        WHEN ds.total_sales > 0 THEN ROUND((COALESCE(cr.total_return_amt, 0) / ds.total_sales) * 100, 2)
        ELSE 0 
    END AS return_percentage
FROM daily_sales ds
LEFT JOIN customer_return_stats cr ON ds.ws_item_sk = cr.sr_item_sk
ORDER BY ds.d_date ASC;
