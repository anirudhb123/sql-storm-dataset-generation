
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(asales.total_quantity, 0) AS total_quantity,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(asales.total_quantity, 0) = 0 THEN NULL 
        ELSE (COALESCE(rs.total_sales, 0) / COALESCE(asales.total_quantity, 0)) 
    END AS avg_sales_price
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rnk = 1
LEFT JOIN 
    AggregatedSales asales ON i.i_item_sk = asales.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    avg_sales_price DESC 
LIMIT 10;
