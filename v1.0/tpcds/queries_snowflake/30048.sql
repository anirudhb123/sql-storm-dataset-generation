
WITH RECURSIVE sales_per_hour AS (
    SELECT 
        d.d_date,
        t.t_hour,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date, t.t_hour
),
customer_stats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    d.d_date,
    COALESCE(sp.total_quantity, 0) AS total_sales_quantity,
    COALESCE(sp.total_sales, 0) AS total_sales_value,
    cs.total_customers,
    cs.avg_purchase,
    cs.female_count,
    cs.male_count
FROM 
    date_dim d
LEFT JOIN 
    sales_per_hour sp ON d.d_date = sp.d_date
LEFT JOIN 
    customer_stats cs ON cs.cd_demo_sk IN (
        SELECT 
            cd_demo_sk 
        FROM 
            customer 
        WHERE 
            c_first_shipto_date_sk = d.d_date_sk
    )
WHERE 
    d.d_month_seq BETWEEN 1 AND 12
ORDER BY 
    d.d_date, total_sales_value DESC;
