
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
customer_info AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_web_orders,
        cs.total_catalog_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_cdemo_sk = cd.cd_demo_sk LIMIT 1)
),
summary_report AS (
    SELECT 
        cd_age_group,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(total_web_sales) AS total_web_sales,
        SUM(total_catalog_sales) AS total_catalog_sales,
        AVG(total_web_orders) AS avg_web_orders_per_customer,
        AVG(total_catalog_orders) AS avg_catalog_orders_per_customer
    FROM 
        (SELECT *,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS cd_age_group
        FROM 
            customer_info) grouped_data
    GROUP BY 
        cd_age_group
)
SELECT 
    cd_age_group,
    customer_count,
    total_web_sales,
    total_catalog_sales,
    avg_web_orders_per_customer,
    avg_catalog_orders_per_customer
FROM 
    summary_report
ORDER BY 
    FIELD(cd_age_group, 'Low', 'Medium', 'High');
