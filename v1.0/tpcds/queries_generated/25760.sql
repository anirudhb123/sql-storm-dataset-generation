
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        ca.ca_city,
        ca.ca_state,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        COALESCE(si.total_sales, 0) AS total_sales,
        si.total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    ci.*,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CombinedInfo ci
WHERE 
    ci.ca_state = 'CA'
ORDER BY 
    total_sales DESC, ci.full_name;
