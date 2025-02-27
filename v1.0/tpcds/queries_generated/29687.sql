
WITH CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM 
        date_dim d
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_credit_rating,
    di.d_year,
    di.d_month_seq,
    si.total_sales,
    si.order_count
FROM 
    customer c
JOIN 
    CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_id
JOIN 
    Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    DateInfo di ON c.c_first_sales_date_sk = di.d_date_sk
JOIN 
    SalesInfo si ON c.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    d.cd_purchase_estimate > 1000
    AND d.cd_marital_status = 'M'
ORDER BY 
    si.total_sales DESC, 
    ca.ca_city, 
    ca.ca_state, 
    customer_name
LIMIT 100;
