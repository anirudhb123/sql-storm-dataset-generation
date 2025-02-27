
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
most_valuable_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.rn <= 10
),
sales_data AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        most_valuable_customers mvc ON ws.ws_bill_customer_sk = mvc.c_customer_id
),
monthly_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        sales_data
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    m.d_year,
    m.d_month_seq,
    m.total_sales,
    RANK() OVER (ORDER BY m.total_sales DESC) AS sales_rank
FROM 
    monthly_sales m
ORDER BY 
    m.d_year, m.d_month_seq;
