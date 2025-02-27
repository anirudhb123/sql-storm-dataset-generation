
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        COUNT(DISTINCT cr_order_number) AS total_orders_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count,
        r.total_returned_quantity,
        r.total_return_amount,
        r.total_return_tax,
        r.total_orders_returned
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
),
AggregatedReturns AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_customers,
        SUM(total_returned_quantity) AS total_quantity,
        SUM(total_return_amount) AS total_amount,
        SUM(total_return_tax) AS total_tax,
        AVG(total_orders_returned) AS avg_orders_returned
    FROM 
        CustomerDemographics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    total_customers,
    total_quantity,
    total_amount,
    total_tax,
    avg_orders_returned
FROM 
    AggregatedReturns
WHERE 
    total_quantity > 0
ORDER BY 
    total_amount DESC, total_quantity DESC;
