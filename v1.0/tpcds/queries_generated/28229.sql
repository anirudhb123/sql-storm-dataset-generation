
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        si.total_sales,
        si.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales' 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_segment,
    CONCAT(SUBSTRING(ca_city, 1, 3), '-', SUBSTRING(ca_state, 1, 2)) AS city_state_code
FROM 
    CombinedInfo
WHERE 
    cd_gender = 'F' AND 
    cd_marital_status = 'M' AND 
    cd_purchase_estimate > 500
ORDER BY 
    total_sales DESC;
