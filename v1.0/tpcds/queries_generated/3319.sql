
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
WebSalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2023
    )
    GROUP BY ws.ws_bill_customer_sk
),
HighValueReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ws.total_web_sales, 0) AS total_web_sales,
        ws.order_count
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
    LEFT JOIN WebSalesData ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hvr.total_returned,
    hvr.total_return_amount,
    hvr.total_web_sales,
    hvr.order_count,
    CASE WHEN hvr.total_returned > 0 THEN 'Yes' ELSE 'No' END AS has_returns
FROM HighValueReturns hvr
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE cd.cd_gender = 'F'
AND hvr.total_web_sales > 5000
ORDER BY hvr.total_returned DESC, hvr.total_web_sales DESC
FETCH FIRST 10 ROWS ONLY;
