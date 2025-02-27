
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
Customer_Avg_Sales AS (
    SELECT 
        total_sales / NULLIF(total_orders, 0) AS avg_sales_per_order,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        Customer_Sales
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS customer_count,
    AVG(avg_sales_per_order) AS avg_sales_per_customer,
    SUM(CASE WHEN total_sales > 1000 THEN 1 ELSE 0 END) AS high_value_customers
FROM 
    Customer_Avg_Sales
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    avg_sales_per_customer DESC, customer_count DESC;
