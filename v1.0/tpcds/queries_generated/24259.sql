
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.marital_status,
    COALESCE(cr.return_count, 0) AS returns,
    COALESCE(cr.total_return_amount, 0) AS return_amount,
    ss.total_sales,
    ss.total_orders,
    COALESCE(ss.sales_rank, 'N/A') AS sales_rank
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    (cd.cd_gender IS NULL OR cd.cd_gender IN ('M', 'F')) AND 
    (cd.cd_purchase_estimate > 1000 OR cd.marital_status = 'Single') AND 
    (ss.total_sales IS NOT NULL OR cr.return_count IS NOT NULL)
ORDER BY 
    ss.total_sales DESC NULLS LAST, 
    cd.marital_status, 
    cd.c_customer_sk;
