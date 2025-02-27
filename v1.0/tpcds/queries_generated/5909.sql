
WITH sales_summary AS (
    SELECT 
        s.s_store_id, 
        d.d_year, 
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        s.s_store_id, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        COUNT(*) AS transactions_count,
        SUM(ss.ss_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
promo_summary AS (
    SELECT 
        p.p_promo_id, 
        COUNT(ss.ss_order_number) AS promo_sales_count, 
        SUM(ss.ss_net_profit) AS total_promo_profit
    FROM 
        promotion p
    JOIN 
        store_sales ss ON p.p_promo_sk = ss.ss_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    s.s_store_name, 
    ss.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_transaction_value,
    cs.transactions_count,
    cs.total_spent,
    ps.promo_sales_count,
    ps.total_promo_profit
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON cs.total_spent > 1000
LEFT JOIN 
    promo_summary ps ON ps.promo_sales_count > 10
JOIN 
    store s ON s.s_store_id = ss.s_store_id
ORDER BY 
    ss.d_year DESC, 
    ss.total_sales DESC;
