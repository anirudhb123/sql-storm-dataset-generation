
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Dates AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim AS d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
Sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales AS ws
    JOIN 
        CustomerInfo AS ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        Dates AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        si.total_sales
    FROM 
        CustomerInfo AS ci
    JOIN 
        Sales AS si ON ci.c_customer_sk = si.ws_bill_customer_sk
    ORDER BY 
        si.total_sales DESC
    LIMIT 10
)
SELECT 
    full_name,
    ca_city,
    total_sales,
    CASE 
        WHEN total_sales > 2000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    TopCustomers;
