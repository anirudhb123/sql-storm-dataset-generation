
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS distinct_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
customer_info AS (
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
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    asum.address_count,
    asum.distinct_street_names,
    si.total_sales,
    si.order_count
FROM 
    customer_info ci
LEFT JOIN 
    address_summary asum ON ci.c_customer_sk = asum.ca_city
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 
    100;
