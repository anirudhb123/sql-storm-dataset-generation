
WITH CustomerWithReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        CASE 
            WHEN COUNT(sr_ticket_number) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesPerCustomer AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        MAX(cd.cd_dep_count) AS highest_dependent_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    IFNULL(spc.total_sales, 0) AS total_sales,
    IFNULL(cwr.total_returns, 0) AS total_returns,
    cwr.return_status,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY spc.total_sales DESC) AS rank_by_sales,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerWithReturns cwr
JOIN 
    SalesPerCustomer spc ON cwr.c_customer_sk = spc.customer_sk
JOIN
    customer c ON c.c_customer_sk = cwr.c_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    spc.total_orders > 0 
    AND (cwr.total_returns IS NULL OR cwr.total_returns > 0)
ORDER BY 
    cd.cd_marital_status, 
    total_sales DESC;
