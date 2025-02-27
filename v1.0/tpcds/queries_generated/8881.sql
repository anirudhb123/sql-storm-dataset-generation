
WITH aggregated_sales AS (
    SELECT 
        s.s_store_id,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions,
        SUM(ss.sales_price) AS total_sales,
        AVG(ss.net_profit) AS avg_profit,
        d.d_year
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.store_sk = s.s_store_sk 
    JOIN 
        date_dim d ON ss.sold_date_sk = d.d_date_sk 
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        s.s_store_id, d.d_year
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.order_number) AS total_web_orders,
        SUM(ws.net_paid) AS total_web_spend,
        cd.edu_status AS education_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
    GROUP BY 
        c.c_customer_id, cd.edu_status
)
SELECT 
    c.c_customer_id,
    cs.total_web_orders,
    cs.total_web_spend,
    as.total_transactions,
    as.total_sales,
    as.avg_profit
FROM 
    customer_stats cs
JOIN 
    aggregated_sales as ON cs.total_web_orders > 0
JOIN 
    customer c ON c.c_customer_id = cs.c_customer_id
ORDER BY 
    cs.total_web_spend DESC
LIMIT 100;
