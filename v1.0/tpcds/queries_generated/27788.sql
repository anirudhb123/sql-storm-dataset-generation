
WITH demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_year,
        ca.ca_city,
        ca.ca_state,
        d.d_date
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_stats AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_report AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cc.c_first_name,
        cc.c_last_name,
        cc.c_email_address,
        cc.ca_city,
        cc.ca_state,
        ss.total_sales,
        ss.order_count,
        ss.avg_sales_price
    FROM 
        demographics cd
    JOIN 
        customer_data cc ON cd.cd_demo_sk = cc.c_customer_sk
    JOIN 
        sales_stats ss ON cc.c_customer_sk = ss.customer_sk
    WHERE 
        (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') 
        OR (cd.cd_marital_status = 'S' AND cd.cd_education_status LIKE '%college%')
)
SELECT 
    f.cd_gender,
    f.cd_marital_status,
    f.c_first_name,
    f.c_last_name,
    f.c_email_address,
    f.ca_city,
    f.ca_state,
    f.total_sales,
    f.order_count,
    f.avg_sales_price
FROM 
    final_report f
ORDER BY 
    f.total_sales DESC
LIMIT 100;
