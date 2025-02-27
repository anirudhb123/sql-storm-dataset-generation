
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_id,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographicsAgg AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dependency_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
PopularItems AS (
    SELECT 
        ws_item_sk AS item_id,
        COUNT(ws_order_number) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
),
ReturnsByItem AS (
    SELECT 
        sr_item_sk AS item_id,
        COUNT(sr_ticket_number) AS returns_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    cda.customer_id,
    cda.cd_gender,
    cda.cd_marital_status,
    cda.cd_education_status,
    cda.total_customers,
    cda.avg_purchase_estimate,
    cda.avg_dependency_count,
    coalesce(cr.total_returned_amount, 0) AS total_returned_amount,
    coalesce(cr.total_returns, 0) AS total_returns,
    pi.item_id AS popular_item_id,
    pi.total_sales AS popular_item_sales,
    rb.item_id AS returned_item_id,
    rb.returns_count AS returns_count,
    rb.total_return_amount AS returned_item_total_amount
FROM 
    CustomerDemographicsAgg cda
LEFT JOIN 
    CustomerReturns cr ON cda.customer_id = cr.customer_id
LEFT JOIN 
    PopularItems pi ON pi.total_sales > 100
LEFT JOIN 
    ReturnsByItem rb ON rb.returns_count > 5
WHERE 
    cda.avg_purchase_estimate > 1000
ORDER BY 
    cda.total_customers DESC, cr.total_returned_amount DESC;
