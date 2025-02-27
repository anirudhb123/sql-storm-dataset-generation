
WITH SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        (ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS item_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
),
DailyReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim
            WHERE d_date >= CURRENT_DATE - INTERVAL '7 days'
        )
    GROUP BY 
        sr_item_sk
),
OverallSales AS (
    SELECT 
        item.i_item_sk,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales,
        COALESCE(dr.total_returns, 0) AS total_returns,
        COALESCE(dr.total_return_amt, 0) AS total_return_amt,
        item.i_item_desc
    FROM 
        item
    LEFT JOIN 
        SalesData sd ON item.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        DailyReturns dr ON item.i_item_sk = dr.sr_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_desc
),
RankedSales AS (
    SELECT 
        *,
        total_sales - total_returns AS net_sales,
        CASE 
            WHEN total_returns = 0 THEN total_sales
            ELSE (total_sales / NULLIF(total_returns, 0))
        END AS return_ratio,
        RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
    FROM 
        OverallSales
),
FinalReport AS (
    SELECT 
        *,
        CASE
            WHEN net_sales > 1000 THEN 'High Performer'
            WHEN net_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        RankedSales
)
SELECT 
    fr.i_item_sk,
    fr.i_item_desc,
    fr.net_sales,
    fr.return_ratio,
    fr.performance_category
FROM 
    FinalReport fr
WHERE 
    fr.performance_category = 'High Performer'
    AND fr.return_ratio < (SELECT AVG(return_ratio) FROM RankedSales)
ORDER BY 
    fr.net_sales DESC
LIMIT 10;
