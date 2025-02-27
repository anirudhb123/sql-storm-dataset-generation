
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(ca_city, 'City', 'Metropolis') AS modified_city,
        UPPER(ca_state) AS upper_state,
        LEFT(ca_zip, 5) AS postal_code
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.modified_city,
        ad.upper_state,
        ad.postal_code
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails AS ad ON c.c_current_addr_sk = ad.ca_address_sk
),
DateDetails AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_day_name
    FROM 
        date_dim AS d
    WHERE 
        d.d_year = 2023
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        CASE 
            WHEN ws.ws_net_paid > 100 THEN 'High Value'
            WHEN ws.ws_net_paid <= 100 AND ws.ws_net_paid > 50 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS order_value_category,
        cd.full_name
    FROM 
        web_sales AS ws
    JOIN 
        CustomerDetails AS cd ON ws.ws_bill_customer_sk = cd.customer_sk
)
SELECT 
    dd.d_date,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_net_paid) AS total_revenue,
    AVG(sd.ws_net_paid) AS average_order_value,
    sd.order_value_category
FROM 
    DateDetails AS dd
JOIN 
    SalesData AS sd ON sd.ws_order_number IS NOT NULL
GROUP BY 
    dd.d_date, sd.order_value_category
ORDER BY 
    dd.d_date, total_revenue DESC;
