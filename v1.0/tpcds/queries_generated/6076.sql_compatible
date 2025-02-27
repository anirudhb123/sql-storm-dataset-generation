
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        ranked_customers rc
    JOIN 
        web_sales ws ON rc.c_customer_id = ws.ws_bill_customer_sk
    WHERE 
        rc.rank <= 10
    GROUP BY 
        rc.c_customer_id, rc.c_first_name, rc.c_last_name, rc.cd_gender
),
sales_summary AS (
    SELECT 
        tc.cd_gender,
        COUNT(tc.c_customer_id) AS customer_count,
        SUM(tc.total_sales) AS total_sales,
        AVG(tc.total_sales) AS avg_sales
    FROM 
        top_customers tc
    GROUP BY 
        tc.cd_gender
)
SELECT 
    ss.cd_gender,
    ss.customer_count,
    ss.total_sales,
    ss.avg_sales,
    ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM 
    sales_summary ss
ORDER BY 
    ss.total_sales DESC;
