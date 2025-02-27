
WITH recursive_date AS (
    SELECT d_date_sk, d_date, d_month_seq, d_year
    FROM date_dim
    WHERE d_date = CURRENT_DATE
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_month_seq, d.d_year
    FROM date_dim d
    JOIN recursive_date rd ON d.d_date_sk = rd.d_date_sk - 1
    WHERE d.d_year = rd.d_year AND d.d_month_seq <= rd.d_month_seq + 2
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(cd.cd_gender, 'U') ORDER BY SUM(ss.ss_net_profit) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING COUNT(DISTINCT ss.ss_ticket_number) > 0
),
shipping_summary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROUND(SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_quantity), 0), 2) AS avg_sales_price
    FROM web_sales ws
    JOIN store st ON ws.ws_store_sk = st.s_store_sk
    WHERE st.s_country IS NOT NULL
    GROUP BY ss.s_store_sk
),
final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name || ' ' || cs.c_last_name AS full_name,
        cs.gender,
        cs.marital_status,
        cs.total_purchases,
        cs.total_profit,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_sales_price,
        CASE 
            WHEN cs.total_profit > 1000 THEN 'High Value'
            WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer_summary cs
    LEFT JOIN shipping_summary ss ON cs.c_customer_sk = ss.s_store_sk
    WHERE cs.gender_rank <= 10
)
SELECT * FROM final_report
WHERE customer_value != 'Low Value'
ORDER BY total_profit DESC, total_sales DESC
LIMIT 50;
