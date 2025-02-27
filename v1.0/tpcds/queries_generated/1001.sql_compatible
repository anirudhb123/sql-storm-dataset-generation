
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
    WHERE i.i_current_price > 0
    GROUP BY cs.cs_item_sk
),
TopSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_sales,
        sd.avg_sales,
        sd.order_count
    FROM SalesData sd
    WHERE sd.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
CombinedSales AS (
    SELECT 
        ts.cs_item_sk,
        ts.total_sales,
        ts.avg_sales,
        ts.order_count,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM TopSales ts
    LEFT JOIN CustomerReturns cr ON ts.cs_item_sk = cr.sr_item_sk
)
SELECT 
    i.i_item_id,
    cs.total_sales,
    cs.avg_sales,
    cs.order_count,
    cs.total_returns,
    cs.total_return_amount,
    CASE 
        WHEN cs.total_sales = 0 THEN 'No Sales'
        ELSE ROUND((cs.total_returns::decimal / NULLIF(cs.total_sales, 0)) * 100, 2) || '%'
    END AS return_rate
FROM CombinedSales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
ORDER BY cs.total_sales DESC;
