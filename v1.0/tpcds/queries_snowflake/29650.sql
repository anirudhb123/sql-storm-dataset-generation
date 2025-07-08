
WITH EnhancedCustomer AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' 
            WHEN cd_gender = 'F' THEN 'Ms. ' 
            ELSE '' 
        END AS salutation,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesPerformance AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ec.c_customer_id,
    ec.full_name,
    ec.salutation,
    ec.ca_city,
    ec.ca_state,
    ec.full_address,
    ec.cd_education_status,
    ec.cd_purchase_estimate,
    sp.total_sales,
    sp.total_orders
FROM 
    EnhancedCustomer ec
LEFT JOIN 
    SalesPerformance sp ON ec.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = sp.ws_bill_customer_sk)
WHERE 
    ec.cd_purchase_estimate > 5000
ORDER BY 
    sp.total_sales DESC;
