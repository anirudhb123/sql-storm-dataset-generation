
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_order_number) AS total_returns,
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
        cd.cd_age_group, 
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnImpact AS (
    SELECT 
        cd.c_customer_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        SalesStatistics s ON cd.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns r ON cd.c_customer_sk = r.cr_returning_customer_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_by_sales,
        RANK() OVER (ORDER BY total_returns DESC) AS rank_by_returns
    FROM 
        ReturnImpact
)
SELECT 
    rc.c_customer_sk,
    cd_gender,
    cd_age_group,
    rank_by_sales,
    rank_by_returns,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_type,
    total_sales,
    total_returns,
    total_return_amount
FROM 
    RankedCustomers rc
WHERE 
    (total_returns / NULLIF(total_sales, 0) > 0.1 OR total_sales < 3000)
ORDER BY 
    customer_value_type, total_sales DESC;
