
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTRING(c.c_email_address from POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateFiltered AS (
    SELECT 
        d.d_date_id,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        DateFiltered df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.email_length,
    cd.email_domain,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    total_spent DESC, full_name
LIMIT 100;
