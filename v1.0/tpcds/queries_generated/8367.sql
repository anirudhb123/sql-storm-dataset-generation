
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.returned_date_sk, 
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        cr.returning_customer_sk, cr.returned_date_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_paid) AS total_sales_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        c.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT cr.returning_customer_sk) AS total_customers_with_returns,
    SUM(cr.total_returned_quantity) AS total_quantity_returned,
    SUM(cr.total_returned_amount) AS total_amount_returned,
    SUM(ss.total_sales) AS total_sales_count,
    SUM(ss.total_sales_value) AS total_sales_value
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.returning_customer_sk
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_sales_value DESC
LIMIT 100;
