
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ss.net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.customer_sk, c.first_name, c.last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM sales_hierarchy
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.net_paid) AS total_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
high_volume_days AS (
    SELECT 
        d.d_date,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM daily_sales d
    WHERE d.total_sales > 100000
),
customer_return_analysis AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(sr.return_amt, 0)) AS total_returns,
        COUNT(DISTINCT sr.ticket_number) AS returns_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_spent,
    tc.order_count,
    hvd.d_date AS peak_sales_date,
    hvd.sales_rank,
    cra.total_returns,
    cra.returns_count
FROM top_customers tc
JOIN high_volume_days hvd ON hvd.sales_rank <= 10
LEFT JOIN customer_return_analysis cra ON tc.customer_sk = cra.c_customer_sk
WHERE tc.total_spent > (SELECT AVG(total_spent) FROM sales_hierarchy)
  AND tc.cd_gender = 'F'
ORDER BY tc.total_spent DESC, hvd.d_date DESC;
