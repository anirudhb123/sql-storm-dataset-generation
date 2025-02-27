
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_discount_amt,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as price_rank
    FROM web_sales ws
    JOIN item it ON ws.ws_item_sk = it.i_item_sk
    WHERE it.i_current_price > 0 
    AND it.i_formulation IS NOT NULL
    AND (it.i_color = 'Red' OR it.i_color IS NULL)
),
total_returns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned 
    FROM store_returns 
    GROUP BY sr_item_sk
),
final_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(tr.total_returned, 0) AS total_returned,
        CASE 
            WHEN rs.price_rank = 1 THEN 'Top Price'
            ELSE 'Regular Price'
        END AS price_category
    FROM ranked_sales rs
    LEFT JOIN total_returns tr ON rs.ws_item_sk = tr.sr_item_sk
)
SELECT 
    fs.ws_item_sk,
    COUNT(fs.ws_order_number) AS order_count,
    SUM(fs.ws_sales_price) AS total_sales,
    SUM(fs.total_returned) AS total_returns,
    CASE 
        WHEN SUM(fs.ws_sales_price) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM final_sales fs
GROUP BY fs.ws_item_sk
HAVING SUM(fs.ws_sales_price) > 1000
ORDER BY total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
