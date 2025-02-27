
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    si.total_sales,
    si.total_orders
FROM 
    CustomerInfo ci
JOIN 
    SalesSummary si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    si.rank <= 10
ORDER BY 
    si.total_sales DESC
UNION ALL
SELECT 
    'Total' AS c_first_name,
    NULL AS c_last_name,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    SUM(total_sales),
    SUM(total_orders)
FROM 
    SalesSummary
WHERE 
    total_orders > 0;
