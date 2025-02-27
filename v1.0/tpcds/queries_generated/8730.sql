
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450005 -- arbitrary date range for demonstration
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_id) AS number_of_customers,
    SUM(COALESCE(cr.total_return_amount, 0)) AS total_returns_amount,
    SUM(COALESCE(sd.total_sales, 0)) AS total_sales_amount,
    AVG(cr.total_returns) AS avg_returns_per_customer
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_returning_customer_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    number_of_customers DESC;
