
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
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
ReturnedOrders AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cdem.c_customer_sk,
    cdem.cd_gender,
    cdem.cd_marital_status,
    MAX(sales.total_sales) AS max_sales,
    COALESCE(ret.return_count, 0) AS total_returns,
    (CASE 
        WHEN MAX(sales.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END) AS sales_status
FROM 
    CustomerDemographics cdem
LEFT JOIN 
    RankedSales sales ON cdem.c_customer_sk = sales.ws_bill_customer_sk AND sales.sales_rank = 1
LEFT JOIN 
    ReturnedOrders ret ON cdem.c_customer_sk = ret.customer_sk
WHERE 
    cdem.cd_purchase_estimate > 500 
    AND (cdem.cd_gender = 'F' OR cdem.cd_marital_status = 'M')
GROUP BY 
    cdem.c_customer_sk, 
    cdem.cd_gender, 
    cdem.cd_marital_status
ORDER BY 
    max_sales DESC NULLS LAST;
