
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        DATE_FORMAT(d.d_date, '%Y-%m') as sales_month
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, sales_month
),
customer_ranking AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_month ORDER BY total_sales DESC) AS rank
    FROM 
        ranked_sales
)
SELECT 
    sales_month,
    cd_gender,
    cd_marital_status,
    AVG(total_sales) AS avg_sales,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    MAX(rank) AS top_rank
FROM 
    customer_ranking
WHERE 
    rank <= 10
GROUP BY 
    sales_month, cd_gender, cd_marital_status
ORDER BY 
    sales_month, avg_sales DESC;
