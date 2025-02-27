
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        MIN(ws.ws_sold_date_sk) AS first_sale_date,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(ss.total_sales) AS total_sales_by_gender_marital
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary ss ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE ss.c_customer_id = c.c_customer_id)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    dg.cd_gender,
    dg.cd_marital_status,
    dg.customer_count,
    dg.total_sales_by_gender_marital,
    CASE 
        WHEN dg.customer_count > 0 THEN dg.total_sales_by_gender_marital / dg.customer_count 
        ELSE 0 
    END AS avg_sales_per_customer
FROM 
    demographics_summary dg
ORDER BY 
    total_sales_by_gender_marital DESC;
