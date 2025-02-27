
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        SUM(sr.return_tax) AS total_return_tax
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_coupon_amt) AS total_coupons
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
FinalData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_discount, 0) AS total_discount,
        COALESCE(sd.total_coupons, 0) AS total_coupons
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.total_returns,
    f.total_return_amount,
    f.total_return_tax,
    f.total_sales,
    f.total_discount,
    f.total_coupons,
    (f.total_sales - f.total_discount - f.total_coupons) AS net_sales
FROM 
    FinalData f
WHERE 
    f.total_sales > 5000
ORDER BY 
    net_sales DESC
LIMIT 50;
