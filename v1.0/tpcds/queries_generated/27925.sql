
WITH Address_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Sales_Summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
Final_Report AS (
    SELECT 
        ai.customer_full_name,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country,
        ss.total_quantity,
        ss.total_sales
    FROM 
        Address_Info ai
    LEFT JOIN 
        Sales_Summary ss ON ai.c_customer_id = ss.ws_bill_cdemo_sk
)
SELECT 
    customer_full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0.00) AS total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    Final_Report
ORDER BY 
    total_sales DESC;
