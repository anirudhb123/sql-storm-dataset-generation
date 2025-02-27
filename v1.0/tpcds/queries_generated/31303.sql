
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
    HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid) AS daily_sales_total,
        COUNT(ws.ws_order_number) AS total_orders
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
all_sales AS (
    SELECT 
        c.customer_unique_id,
        sh.total_sales,
        sh.avg_net_paid,
        ds.daily_sales_total,
        ds.total_orders,
        ROW_NUMBER() OVER (PARTITION BY sh.cd_income_band_sk ORDER BY sh.total_sales DESC) AS rank
    FROM sales_hierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
    JOIN daily_sales ds ON ds.total_orders > 10
)
SELECT 
    a.customer_unique_id,
    a.total_sales,
    a.avg_net_paid,
    a.daily_sales_total,
    a.total_orders,
    CASE 
        WHEN a.daily_sales_total > 5000 THEN 'High'
        WHEN a.daily_sales_total BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM (
    SELECT *, 
           DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank 
    FROM all_sales
) a
WHERE a.rank <= 10;
