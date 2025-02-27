
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
best_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.order_count,
        W.COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer_sales cs
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE 
        cs.order_count > 0 
        AND cs.spending_rank <= 100
),
store_sales_data AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS store_total_sales
    FROM 
        store_sales ss 
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ss.ss_store_sk
),
high_sales_stores AS (
    SELECT 
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_store_sk,
        COALESCE(ssd.store_total_sales, 0) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales_data ssd ON s.s_store_sk = ssd.ss_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL
)
SELECT 
    b.c_customer_id,
    b.total_spent,
    b.order_count,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.total_sales
FROM 
    best_customers b
JOIN 
    high_sales_stores s ON b.total_spent > s.total_sales * 0.1
ORDER BY 
    b.total_spent DESC, s.total_sales DESC;
