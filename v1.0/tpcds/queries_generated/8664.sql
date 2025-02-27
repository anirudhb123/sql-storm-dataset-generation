
WITH CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_return_time_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT wr_returning_customer_sk) AS unique_returning_customers
    FROM web_returns
    WHERE wr_returned_date_sk >= DATEADD(DAY, -30, CURRENT_DATE) 
    GROUP BY wr_returned_date_sk, wr_return_time_sk, wr_item_sk
),
StoreSales AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sold_quantity,
        SUM(ss_sales_price) AS total_sales_value
    FROM store_sales
    WHERE ss_sold_date_sk >= DATEADD(DAY, -30, CURRENT_DATE)
    GROUP BY ss_sold_date_sk, ss_item_sk
),
ReturnMetrics AS (
    SELECT 
        sr.item_sk,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ss.total_sold_quantity, 0) AS total_sold_quantity,
        COALESCE(ss.total_sales_value, 0) AS total_sales_value
    FROM 
        (SELECT DISTINCT wr_item_sk FROM web_returns) AS sr
    LEFT JOIN CustomerReturns cr ON sr.wr_item_sk = cr.wr_item_sk
    LEFT JOIN StoreSales ss ON sr.wr_item_sk = ss.ss_item_sk
),
PerformanceMetrics AS (
    SELECT 
        item_sk,
        total_sold_quantity,
        total_returned_quantity,
        total_sales_value,
        total_returned_amount,
        CASE 
            WHEN total_sold_quantity > 0 
            THEN total_returned_quantity * 100.0 / total_sold_quantity 
            ELSE 0 
        END AS return_rate,
        CASE 
            WHEN total_returned_amount > 0
            THEN total_returned_amount / NULLIF(total_sales_value, 0)
            ELSE 0 
        END AS return_value_ratio
    FROM ReturnMetrics
)
SELECT 
    item_sk,
    total_sold_quantity,
    total_returned_quantity,
    total_sales_value,
    total_returned_amount,
    return_rate,
    return_value_ratio
FROM PerformanceMetrics
ORDER BY return_rate DESC
LIMIT 100;
