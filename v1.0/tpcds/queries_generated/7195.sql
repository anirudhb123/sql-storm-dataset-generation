
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_ext_sales_price) AS total_sales_amount,
        SUM(ss_ext_discount_amt) AS total_discount_amount,
        AVG(ss_sales_price) AS average_sales_price,
        SUM(CASE WHEN d_week_seq = (SELECT MAX(d_week_seq) FROM date_dim) THEN ss_quantity ELSE 0 END) AS current_week_sales,
        SUM(CASE WHEN d_week_seq = (SELECT MAX(d_week_seq) - 1 FROM date_dim) THEN ss_quantity ELSE 0 END) AS last_week_sales
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        c.c_customer_id
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(total_sales_amount) AS avg_sales_per_customer
    FROM 
        sales_summary s
    JOIN 
        customer_demographics cd ON s.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    d.cd_gender,
    d.customer_count,
    d.avg_sales_per_customer,
    CASE 
        WHEN d.customer_count > 100 THEN 'High Engagement'
        WHEN d.customer_count BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM 
    demographics_summary d
WHERE 
    d.avg_sales_per_customer > 500
ORDER BY 
    d.avg_sales_per_customer DESC;
