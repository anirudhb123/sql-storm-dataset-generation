
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(*) AS return_count
    FROM 
        store_returns 
    GROUP BY 
        sr_returning_customer_sk
), 
MaxReturns AS (
    SELECT 
        cr.returning_customer_sk, 
        cr.total_returned_quantity, 
        cr.total_returned_amount,
        RANK() OVER (ORDER BY cr.total_returned_amount DESC) AS rank
    FROM 
        CustomerReturns cr
), 
CustomerDemo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    sr.total_returned_quantity,
    sr.total_returned_amount,
    ss.total_sales,
    ss.order_count
FROM 
    CustomerDemo cd
LEFT JOIN 
    MaxReturns sr ON cd.c_customer_sk = sr.returning_customer_sk AND sr.rank <= 5
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cd.cd_gender IS NOT NULL
    AND (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL)
    AND (ss.total_sales > 1000 OR ss.order_count IS NULL)
ORDER BY 
    cd.cd_gender, 
    total_returned_amount DESC;
