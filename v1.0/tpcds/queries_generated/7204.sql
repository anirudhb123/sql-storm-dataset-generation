
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
combined_data AS (
    SELECT 
        cu.c_first_name,
        cu.c_last_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_purchase_estimate,
        cu.cd_credit_rating,
        cu.cd_dep_count,
        sd.total_sales,
        sd.total_orders
    FROM 
        customer_data cu
    JOIN 
        sales_data sd ON cu.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.gender,
    SUM(cd.total_sales) AS total_sales_per_gender,
    AVG(cd.total_orders) AS avg_orders_per_gender,
    COUNT(cd.c_first_name) AS customer_count
FROM 
    combined_data cd
GROUP BY 
    cd.cd_gender
ORDER BY 
    total_sales_per_gender DESC;
