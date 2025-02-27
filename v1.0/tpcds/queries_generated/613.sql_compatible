
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_sales_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
    COALESCE(SD.total_sales, 0) AS total_sales,
    COALESCE(CR.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(CR.total_return_amount, 0) AS total_return_amount,
    COALESCE(WR.total_return_quantity, 0) AS web_total_return_quantity,
    COALESCE(WR.total_return_amount, 0) AS web_total_return_amount
FROM 
    customer AS c
LEFT JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesData AS SD ON c.c_customer_sk = SD.customer_sk
LEFT JOIN 
    CustomerReturns AS CR ON c.c_customer_sk = CR.cr_returning_customer_sk
FULL OUTER JOIN 
    WebReturns AS WR ON c.c_customer_sk = WR.wr_returning_customer_sk
WHERE 
    (COALESCE(SD.total_sales, 0) > 1000 OR CR.total_returns IS NOT NULL OR WR.total_returns IS NOT NULL)
    AND (cd.cd_credit_rating IS NULL OR cd.cd_credit_rating <> 'Bad')
ORDER BY 
    gender, marital_status;
