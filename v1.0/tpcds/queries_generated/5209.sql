
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_order_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
customer_ranking AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        last_order_date,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
)
SELECT 
    c.c_customer_id,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    cr.total_sales,
    cr.total_orders,
    cr.last_order_date,
    cr.sales_rank
FROM 
    customer_ranking cr
JOIN 
    customer_demographics c ON cr.c_customer_id = c.c_customer_id
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    c.cd_gender, cr.total_sales DESC;
