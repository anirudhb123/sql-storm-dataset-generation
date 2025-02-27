
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 
        AND s.s_state = 'CA'
    GROUP BY 
        s.s_store_id
),
top_stores AS (
    SELECT 
        s_store_id,
        total_quantity_sold,
        total_revenue,
        avg_sales_price,
        total_transactions,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        sales_summary
)
SELECT 
    ts.s_store_id,
    ts.total_quantity_sold,
    ts.total_revenue,
    ts.avg_sales_price,
    ts.total_transactions,
    d.d_month_name
FROM 
    top_stores ts
JOIN 
    date_dim d ON d.d_year = 2022
WHERE 
    ts.revenue_rank <= 5
ORDER BY 
    ts.total_revenue DESC;
