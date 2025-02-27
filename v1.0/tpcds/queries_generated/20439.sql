
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
return_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
product_metrics AS (
    SELECT 
        i.i_item_id,
        COALESCE(sd.total_quantity, 0) AS total_sold,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(sd.total_sales, 0) AS total_sales,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returned_amt, 0)) AS net_sales,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL 
            ELSE (COALESCE(rd.total_returned_amt, 0) / COALESCE(sd.total_sales, 0)) * 100 
        END AS return_percentage
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN return_data rd ON i.i_item_sk = rd.wr_item_sk
),
final_selection AS (
    SELECT 
        pm.i_item_id,
        pm.total_sold,
        pm.total_returned,
        pm.net_sales,
        pm.return_percentage,
        RANK() OVER (ORDER BY pm.return_percentage DESC NULLS LAST) AS return_rank,
        ROW_NUMBER() OVER (PARTITION BY pm.return_percentage IS NOT NULL ORDER BY pm.net_sales DESC) AS adjusted_rank
    FROM product_metrics pm
)
SELECT 
    fs.i_item_id,
    fs.total_sold,
    fs.total_returned,
    fs.net_sales,
    fs.return_percentage,
    fs.return_rank,
    fs.adjusted_rank,
    CASE 
        WHEN fs.return_percentage IS NULL THEN 'No Returns'
        WHEN fs.return_percentage > 10 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_category
FROM final_selection fs
WHERE (fs.return_percentage IS NULL OR fs.return_percentage < 50)
ORDER BY fs.return_category DESC, fs.net_sales DESC;
