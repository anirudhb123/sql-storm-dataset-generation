
WITH address_info AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        dd.d_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.gender,
    d.cd_marital_status,
    d.cd_education_status,
    s.d_date,
    COUNT(s.ws_order_number) AS total_orders,
    SUM(s.ws_sales_price) AS total_sales,
    SUM(s.ws_net_profit) AS total_profit
FROM 
    address_info a
JOIN 
    customer c ON a.ca_address_id = c.c_customer_id
JOIN 
    demographic_info d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    sales_info s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    s.ws_sales_price > 0
    AND s.d_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    a.full_address, a.ca_city, a.ca_state, d.gender, d.cd_marital_status, d.cd_education_status, s.d_date
ORDER BY 
    total_sales DESC, total_orders DESC;
