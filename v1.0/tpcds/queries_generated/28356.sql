
WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, CHARINDEX('@', c.c_email_address) + 1, LEN(c.c_email_address)) AS domain,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
city_info AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ci.full_name,
    ci.domain,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ci.cd_dep_count,
    ci.cd_dep_employed_count,
    ci.cd_dep_college_count,
    ci.cd_gender AS gender_output,
    cc.address_count AS city_address_count,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS total_orders
FROM 
    customer_info ci
LEFT JOIN 
    city_info cc ON ci.domain LIKE '%' + cc.ca_city + '%'
LEFT JOIN 
    sales_summary ss ON ci.full_name LIKE '%' + ss.ws_bill_cdemo_sk + '%'
WHERE 
    ci.cd_purchase_estimate > 1000
    AND (ci.cd_marital_status = 'M' OR ci.cd_gender = 'F')
ORDER BY 
    total_sales DESC
LIMIT 100;
