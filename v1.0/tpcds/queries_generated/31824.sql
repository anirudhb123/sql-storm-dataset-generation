
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk
    HAVING SUM(ws_ext_sales_price) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_sales DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status
    FROM sales_summary cs
    JOIN customer_info ci ON cs.c_customer_sk = ci.c_customer_sk
    WHERE cs.sales_rank <= 10
)
SELECT 
    t.c_customer_sk,
    t.total_sales,
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    t.cd_marital_status,
    COUNT(DISTINCT s.ss_ticket_number) AS store_ticket_count,
    COALESCE(SUM(sr_return_amt), 0) AS total_returns,
    AVG(ss.ss_ext_sales_price) OVER (PARTITION BY t.cd_gender) AS avg_sales_per_gender,
    STRING_AGG(DISTINCT CONCAT_WS(' ', s.s_store_name, s.s_city, s.s_state)) AS store_info
FROM top_customers t
LEFT JOIN store_sales s ON t.c_customer_sk = s.ss_customer_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = t.c_customer_sk
LEFT JOIN store st ON s.ss_store_sk = st.s_store_sk
GROUP BY t.c_customer_sk, t.total_sales, t.c_first_name, t.c_last_name, t.cd_gender, t.cd_marital_status
ORDER BY total_sales DESC;
