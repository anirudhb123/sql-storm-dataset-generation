
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *,
        CASE WHEN total_sales > 1000 THEN 'Gold'
             WHEN total_sales > 500 THEN 'Silver'
             ELSE 'Bronze' END AS customer_tier
    FROM sales_summary
    WHERE sales_rank <= 10
),
recent_dates AS (
    SELECT 
        d.d_date
    FROM date_dim AS d
    WHERE d.d_date >= (SELECT MAX(d1.d_date) FROM date_dim AS d1) - INTERVAL '30 days'
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.customer_tier,
    rd.d_date AS recent_date,
    COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS web_sales
FROM 
    top_customers AS tc
LEFT JOIN 
    recent_dates AS rd ON 1 = 1
LEFT JOIN 
    web_sales AS ws ON tc.c_customer_sk = ws.ws_bill_customer_sk AND rd.d_date = (SELECT MAX(d2.d_date) FROM date_dim AS d2 WHERE d2.d_date = rd.d_date)
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_sales, tc.customer_tier, rd.d_date
ORDER BY 
    tc.total_sales DESC;
