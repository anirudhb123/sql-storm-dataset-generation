
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS average_order_value
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                             AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
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
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
combined_data AS (
    SELECT 
        cu.customer_id,
        cu.c_first_name,
        cu.c_last_name,
        cu.cd_gender,
        cu.cd_marital_status,
        sd.total_sales,
        sd.total_orders,
        sd.average_order_value
    FROM 
        sales_data sd
    JOIN 
        customer_data cu ON sd.customer_id = cu.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.customer_id) AS unique_customers,
    SUM(cd.total_sales) AS total_revenue,
    AVG(cd.average_order_value) AS avg_order_value
FROM 
    combined_data cd
WHERE 
    cd.total_sales > 1000
GROUP BY 
    cd.c_gender, cd.c_marital_status
ORDER BY 
    total_revenue DESC
LIMIT 10;
