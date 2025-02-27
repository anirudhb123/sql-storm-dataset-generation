
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        wc.web_site_id
    FROM 
        web_sales ws
    JOIN 
        web_site wc ON ws.ws_web_site_sk = wc.web_site_sk
    GROUP BY 
        ws.ws_sold_date_sk, wc.web_site_id
),
CustomerSales AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.gender,
        s.total_quantity,
        s.total_sales,
        d.d_date
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData s ON ci.c_customer_sk = s.ws_bill_customer_sk
    JOIN 
        date_dim d ON s.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    full_name,
    gender,
    SUM(total_quantity) AS total_purchased,
    SUM(total_sales) AS total_spent,
    COUNT(d_date) AS purchase_days
FROM 
    CustomerSales
GROUP BY 
    full_name, gender
HAVING 
    SUM(total_sales) > 5000
ORDER BY 
    total_spent DESC;
