
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COUNT(DISTINCT ss.ticket_number) AS store_sales_count,
        SUM(ss.net_paid) AS total_store_sales,
        AVG(ss.net_profit) AS avg_store_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_marital_status
),
date_range AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS month_rank
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2019 AND 2021
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        COUNT(ws.ws_order_number) AS promo_sales_count,
        SUM(ws.ws_net_profit) AS total_promo_net_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name, p.p_start_date_sk
)
SELECT 
    cs.c_customer_sk,
    cs.marital_status,
    dr.d_year,
    dr.d_day_name,
    COALESCE(ps.promo_sales_count, 0) AS promo_sales_count,
    COALESCE(ps.total_promo_net_profit, 0) AS total_promo_net_profit,
    cs.store_sales_count,
    cs.total_store_sales,
    cs.avg_store_profit,
    CASE 
        WHEN cs.total_store_sales > 1000 THEN 'High spender'
        WHEN cs.total_store_sales BETWEEN 500 AND 1000 THEN 'Medium spender'
        ELSE 'Low spender'
    END AS spending_category
FROM 
    customer_stats cs
LEFT JOIN 
    date_range dr ON dr.month_rank = 1
LEFT JOIN 
    promotions ps ON cs.c_customer_sk = ps.promo_sales_count
WHERE 
    (cs.total_store_sales IS NOT NULL OR cs.store_sales_count > 0)
ORDER BY 
    cs.total_store_sales DESC, cs.c_customer_sk;
