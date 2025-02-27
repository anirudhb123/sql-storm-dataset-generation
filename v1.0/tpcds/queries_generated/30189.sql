
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        COUNT(*) AS total_sales,
        SUM(ss_sales_price) AS total_revenue
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20230131
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        sh.ss_store_sk,
        sh.total_sales + COALESCE(SUM(ss.total_sales), 0),
        sh.total_revenue + COALESCE(SUM(ss.total_revenue), 0)
    FROM 
        sales_hierarchy sh
    LEFT JOIN store_sales ss ON sh.ss_store_sk = ss_store_sk
    WHERE 
        ss.sold_date_sk BETWEEN 20230201 AND 20230228
    GROUP BY 
        sh.ss_store_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        customer_id,
        cd_gender,
        cd_marital_status
    FROM 
        customer_summary
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM customer_summary)
)
SELECT 
    s.s_store_sk,
    SUM(s.total_sales) AS overall_store_sales,
    COUNT(DISTINCT t.customer_id) AS happy_customers,
    AVG(t.total_spent) AS avg_spent_per_happy_customer,
    MAX(s.total_revenue) AS max_revenue_per_store
FROM 
    sales_hierarchy s
LEFT JOIN top_customers t ON s.ss_store_sk = t.customer_id
GROUP BY 
    s.s_store_sk
HAVING 
    MAX(s.total_revenue) > 1000
ORDER BY 
    overall_store_sales DESC;
