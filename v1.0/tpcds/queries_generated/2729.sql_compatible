
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.ws_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(s.total_store_sales, 0) AS total_store_sales,
    COALESCE(rs.total_sales, 0) AS total_web_sales,
    CASE 
        WHEN COALESCE(s.total_store_sales, 0) > COALESCE(rs.total_sales, 0) THEN 'Store Sales Higher'
        WHEN COALESCE(s.total_store_sales, 0) < COALESCE(rs.total_sales, 0) THEN 'Web Sales Higher'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM customer_info ci
LEFT JOIN store_sales_summary s ON ci.c_customer_sk = s.ss_store_sk
LEFT JOIN ranked_sales rs ON s.ss_store_sk = rs.web_site_sk AND rs.sales_rank = 1
WHERE ci.cd_gender IS NOT NULL
    AND (ci.cd_marital_status IN ('M', 'S') OR ci.cd_marital_status IS NULL)
ORDER BY ci.c_last_name, ci.c_first_name;
