
WITH RECURSIVE sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY s_store_sk
),
customer_rankings AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_by_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, c.c_first_name, c.c_last_name
),
active_customers AS (
    SELECT 
        DISTINCT c_customer_sk
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    ss.s_store_sk,
    ss.total_sales,
    ss.transaction_count,
    cr.c_first_name, 
    cr.c_last_name, 
    cr.rank_by_gender,
    COALESCE(ss.transaction_count / NULLIF(s.sales_count, 0), 0) AS transaction_ratio
FROM sales_summary ss
JOIN (
    SELECT 
        COUNT(DISTINCT ss_ticket_number) AS sales_count, 
        ss_store_sk 
    FROM store_sales 
    GROUP BY ss_store_sk
) s ON ss.s_store_sk = s.ss_store_sk
JOIN customer_rankings cr ON cr.c_customer_sk IN (SELECT c_customer_sk FROM active_customers)
WHERE ss.sales_rank <= 5
ORDER BY ss.total_sales DESC, cr.rank_by_gender;
