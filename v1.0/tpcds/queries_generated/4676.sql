
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_item_sk) AS total_returns,
        SUM(cr_return_amt) AS total_return_amount,
        SUM(cr_return_tax) AS total_tax,
        SUM(cr_return_amt_inc_tax) AS total_amount_inclusive_tax
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count
    FROM 
        customer_demographics cd
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cr.total_returns,
    cr.total_return_amount,
    cr.total_tax,
    sd.total_sales,
    sd.average_sales_price
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    (cr.total_returns IS NULL OR cr.total_returns > 0)
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    AND (sd.total_sales IS NOT NULL AND sd.average_sales_price > 50.00)
ORDER BY 
    cr.total_return_amount DESC NULLS LAST,
    sd.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
