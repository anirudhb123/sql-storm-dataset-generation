
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_sales_price) AS total_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_education_status IN ('Bachelor', 'Master')
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
high_value_customers AS (
    SELECT 
        c.customer_id, 
        c.first_name, 
        c.last_name, 
        c.total_sales_quantity, 
        c.total_sales_amount, 
        c.order_count
    FROM 
        customer_data c
    WHERE 
        c.total_sales_amount > (SELECT AVG(total_sales_amount) FROM customer_data)
),
sales_summary AS (
    SELECT 
        hv.customer_id, 
        hv.first_name, 
        hv.last_name, 
        hv.total_sales_quantity, 
        hv.total_sales_amount, 
        hv.order_count,
        RANK() OVER (ORDER BY hv.total_sales_amount DESC) AS sales_rank
    FROM 
        high_value_customers hv
)
SELECT 
    ss.customer_id,
    ss.first_name,
    ss.last_name,
    ss.total_sales_quantity,
    ss.total_sales_amount,
    ss.order_count,
    ss.sales_rank
FROM 
    sales_summary ss
WHERE 
    ss.sales_rank <= 10
ORDER BY 
    ss.sales_rank;
