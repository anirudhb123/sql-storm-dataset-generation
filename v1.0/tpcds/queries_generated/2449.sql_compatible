
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
SalesData AS (
    SELECT 
        w.ws_bill_customer_sk,
        SUM(w.ws_ext_sales_price) AS total_web_sales,
        SUM(w.ws_quantity) AS total_web_sales_quantity
    FROM web_sales w
    WHERE w.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
    )
    GROUP BY w.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cr.c_customer_id,
        COALESCE(sd.total_web_sales, 0) AS total_web_sales,
        cr.total_store_returns,
        CASE 
            WHEN cr.total_store_returns > 0 THEN 'Returned Customer'
            ELSE 'New Customer'
        END AS customer_type
    FROM CustomerReturns cr
    LEFT JOIN SalesData sd ON cr.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    customer_type,
    COUNT(*) AS customer_count,
    AVG(total_web_sales) AS avg_web_sales,
    SUM(total_store_returns) AS total_returns
FROM CombinedData
GROUP BY customer_type
ORDER BY customer_type;
