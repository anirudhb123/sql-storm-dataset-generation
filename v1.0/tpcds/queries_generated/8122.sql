
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_net_paid) AS avg_transaction_value
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByMonth AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS sales_month,
        SUM(cs.total_revenue) AS monthly_revenue,
        SUM(cs.total_sales) AS total_orders
    FROM 
        CustomerSales cs
    JOIN 
        date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        sales_month
),
TopRevenueStores AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS total_store_revenue
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
    ORDER BY 
        total_store_revenue DESC
    LIMIT 5
)
SELECT 
    sm.sm_type,
    sbs.sales_month,
    sbs.monthly_revenue,
    sbs.total_orders,
    tr.total_store_revenue
FROM 
    SalesByMonth sbs
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk IN (
        SELECT DISTINCT ss.ss_ship_mode_sk FROM store_sales ss
    )
JOIN 
    TopRevenueStores tr ON tr.total_store_revenue > 10000
ORDER BY 
    sbs.sales_month DESC, tr.total_store_revenue DESC;
