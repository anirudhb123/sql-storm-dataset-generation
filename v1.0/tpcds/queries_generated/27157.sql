
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        REPLACE(REPLACE(ca.ca_street_name, ' St.', ''), ' Ave.', '') AS street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ci.full_name,
    SUM(sd.ws_sales_price) AS total_spent,
    COUNT(sd.ws_order_number) AS total_orders,
    AVG(sd.ws_sales_price) AS avg_order_value,
    STRING_AGG(DISTINCT ci.ca_city, ', ') AS unique_cities,
    ROW_NUMBER() OVER (PARTITION BY ci.gender ORDER BY SUM(sd.ws_sales_price) DESC) AS rank_by_gender
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_order_number
GROUP BY 
    ci.full_name, ci.gender
HAVING 
    SUM(sd.ws_sales_price) > 1000
ORDER BY 
    total_spent DESC;
