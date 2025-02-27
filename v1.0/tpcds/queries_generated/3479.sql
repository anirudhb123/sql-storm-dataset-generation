
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_web_sales) AS avg_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
sales_rank AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        avg_sales,
        RANK() OVER (PARTITION BY cd_gender ORDER BY avg_sales DESC) AS sales_rank
    FROM 
        demographic_analysis cd
)
SELECT 
    sr.cd_gender,
    sr.cd_marital_status,
    sr.avg_sales,
    CASE 
        WHEN sr.sales_rank = 1 THEN 'Top'
        WHEN sr.sales_rank <= 3 THEN 'Top 3'
        ELSE 'Others'
    END AS sales_category
FROM 
    sales_rank sr
WHERE 
    sr.avg_sales IS NOT NULL
ORDER BY 
    sr.cd_gender, sr.sales_rank;

