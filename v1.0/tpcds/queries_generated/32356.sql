
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnsAnalysis AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(s.total_sales, 0) AS total_sales_value,
    COALESCE(r.total_returns, 0) AS total_returned_quantity,
    COALESCE(r.total_return_value, 0) AS total_returned_value,
    CASE 
        WHEN COALESCE(s.total_quantity, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(r.total_returns, 0) > COALESCE(s.total_quantity, 0) THEN 'High Return Rate'
        ELSE 'Normal'
    END AS sales_status
FROM 
    item i
LEFT JOIN 
    RecursiveSales s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    ReturnsAnalysis r ON i.i_item_sk = r.wr_item_sk
WHERE 
    i.i_current_price > 20.00
    AND (s.total_quantity > 100 OR r.total_returns IS NOT NULL)
ORDER BY 
    total_sales_value DESC
LIMIT 10;
