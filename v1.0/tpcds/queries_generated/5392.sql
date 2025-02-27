
WITH aggregated_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        SUM(ss.net_paid) AS total_sales,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers,
        AVG(ss.net_profit) AS avg_profit_per_sale
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.net_paid) AS total_spent
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
sales_per_store AS (
    SELECT 
        s.store_id,
        SUM(ss.net_paid) AS store_sales
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.store_sk = s.store_sk
    GROUP BY 
        s.store_id
)
SELECT 
    ag.d_year,
    ag.d_month_seq,
    ag.d_week_seq,
    ag.total_sales,
    ag.unique_customers,
    ag.avg_profit_per_sale,
    tc.c_customer_id AS top_customer,
    tc.total_spent,
    sp.store_id,
    sp.store_sales
FROM 
    aggregated_sales ag
JOIN 
    top_customers tc ON ag.total_sales > 10000
JOIN 
    sales_per_store sp ON sp.store_sales > (SELECT AVG(store_sales) FROM sales_per_store)
ORDER BY 
    ag.d_year, ag.d_month_seq, ag.d_week_seq, tc.total_spent DESC;
