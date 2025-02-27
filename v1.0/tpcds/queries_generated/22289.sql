
WITH RankedReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_return_time_sk,
        wr_item_sk,
        wr_returning_customer_sk,
        wr_return_quantity,
        SUM(wr_return_quantity) OVER (PARTITION BY wr_item_sk ORDER BY wr_returned_date_sk) AS cumulative_returns,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY wr_returned_date_sk) AS rn
    FROM web_returns
    WHERE wr_return_quantity IS NOT NULL
), 
TopReturners AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(*) AS return_count
    FROM RankedReturns
    GROUP BY wr_returning_customer_sk
    HAVING SUM(wr_return_quantity) > 0 
), 
ReturnStatistics AS (
    SELECT 
        TR.wr_returning_customer_sk,
        DENSE_RANK() OVER (ORDER BY TR.total_returned DESC) AS rank,
        TR.return_count,
        CASE 
            WHEN TR.return_count > 1 THEN 'Frequent Returner' 
            ELSE 'One-Time Returner' 
        END AS return_category
    FROM TopReturners TR
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
    GROUP BY ws_item_sk
)
SELECT 
    RS.wr_returning_customer_sk,
    RS.rank,
    RS.return_category,
    COALESCE(SD.total_sales_price, 0) AS total_sales_from_returns,
    ROUND((COALESCE(SD.total_sales_price, 0) / NULLIF(TR.total_returned, 0)), 2) AS sales_per_return,
    CASE 
        WHEN SD.total_orders > 0 THEN ROUND(100.0 * (TR.return_count / SD.total_orders), 2) 
        ELSE NULL 
    END AS return_rate_percentage
FROM ReturnStatistics RS
LEFT JOIN TopReturners TR ON RS.wr_returning_customer_sk = TR.wr_returning_customer_sk
LEFT JOIN SalesData SD ON TR.wr_returning_customer_sk = SD.ws_item_sk
WHERE RS.rank <= 10
ORDER BY RS.rank;
