
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        h.hd_demo_sk AS c_customer_sk,
        COALESCE(hd.total_spent, 0) AS total_spent
    FROM 
        household_demographics h 
    LEFT JOIN sales_hierarchy hd ON h.hd_demo_sk = hd.c_customer_sk
    WHERE 
        h.hd_dep_count IS NOT NULL 
        AND h.hd_dep_count > 0
),
ranked_sales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_spent,
        RANK() OVER (ORDER BY sh.total_spent DESC) AS spend_rank
    FROM 
        sales_hierarchy sh
),
top_spenders AS (
    SELECT 
        rs.c_customer_sk,
        rs.c_first_name,
        rs.c_last_name,
        rs.total_spent
    FROM 
        ranked_sales rs
    WHERE 
        rs.spend_rank <= 10
),
customer_returns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_spent,
    COALESCE(cr.total_returns, 0) AS total_returns,
    (ts.total_spent - COALESCE(cr.total_returns, 0)) AS net_spent,
    CASE 
        WHEN ts.total_spent > 500 THEN 'High Value'
        WHEN ts.total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    top_spenders ts
LEFT JOIN customer_returns cr ON ts.c_customer_sk = cr.sr_customer_sk
ORDER BY 
    net_spent DESC;
