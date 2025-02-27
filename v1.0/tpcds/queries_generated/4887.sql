
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupon_amt,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
),
IncomeBandSummary AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_coupon_amt, 0) AS total_coupon_amt,
    ibs.customer_count,
    ibs.max_purchase_estimate
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    IncomeBandSummary ibs ON c.c_current_hdemo_sk = ibs.hd_demo_sk
WHERE 
    c.c_birth_year > 1980
    AND c.c_preferred_cust_flag = 'Y'
ORDER BY 
    total_sales DESC, total_return_quantity DESC;
