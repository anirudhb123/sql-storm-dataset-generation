
WITH Address_City AS (
    SELECT 
        ca_city, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
Customer_Demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate,
        CONCAT(cd_gender, '_', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
),
Sales_Data AS (
    SELECT 
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_net_paid,
        d.d_date,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    a.ca_city,
    SUM(sd.ws_net_paid) AS total_sales,
    COUNT(DISTINCT sd.c_customer_id) AS unique_customers,
    COUNT(sd.ws_order_number) AS total_orders,
    SUBSTRING(a.full_address, 1, 30) AS short_address,
    GROUP_CONCAT(DISTINCT cd.gender_marital_status ORDER BY cd.gender_marital_status ASC) AS demographics_summary
FROM 
    Address_City a
JOIN 
    Sales_Data sd ON a.ca_city = sd.c_customer_id
JOIN 
    Customer_Demographics cd ON sd.c_customer_id = cd.cd_demo_sk
GROUP BY 
    a.ca_city, a.full_address
ORDER BY 
    total_sales DESC
LIMIT 10;
