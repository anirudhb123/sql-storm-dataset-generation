
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(CAST(cd.cd_dep_count AS VARCHAR), 'N/A') AS dependents,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.dependents,
    cd.credit_rating,
    sd.total_sales,
    sd.order_count
FROM 
    CustomerData cd
JOIN 
    SalesData sd ON cd.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = sd.ws_order_number LIMIT 1))
WHERE 
    cd.ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    sd.total_sales DESC;
