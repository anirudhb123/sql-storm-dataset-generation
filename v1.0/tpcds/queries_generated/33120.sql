
WITH RECURSIVE sales_date AS (
    SELECT d_date_sk, d_date, 1 AS level
    FROM date_dim
    WHERE d_date = '2023-10-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, level + 1
    FROM date_dim d
    JOIN sales_date sd ON d.d_date_sk = sd.d_date_sk + 1
    WHERE d.d_date <= '2023-10-31'
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        COALESCE(ws_bill_customer_sk, ss_customer_sk) AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_list_price) AS avg_price,
        COUNT(DISTINCT ws_bill_cdemo_sk) AS distinct_customers
    FROM web_sales ws
    FULL OUTER JOIN store_sales ss ON ws_order_number = ss_ticket_number
    GROUP BY customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ss.total_sales,
    ss.order_count,
    ss.avg_price,
    sd.d_date,
    ROW_NUMBER() OVER (PARTITION BY ci.c_customer_sk ORDER BY ss.total_sales DESC) AS sales_rank
FROM customer_info ci
JOIN sales_summary ss ON ci.c_customer_sk = ss.customer_sk
JOIN sales_date sd ON sd.d_date_sk = ws_sold_date_sk
WHERE (ss.total_sales > 1000 OR ci.cd_gender = 'F')
  AND (ci.purchase_estimate BETWEEN 100 AND 5000)
  AND ss.order_count > 0
ORDER BY ss.total_sales DESC, ci.c_last_name, ci.c_first_name;
