
WITH RECURSIVE income_hierarchy AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 0 AS level
    FROM income_band
    WHERE ib_upper_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, ih.level + 1
    FROM income_band ib
    JOIN income_hierarchy ih ON ib.ib_lower_bound >= ih.ib_upper_bound
),
aggregated_sales AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450600 -- Arbitrary date range
    GROUP BY ws_bill_cdemo_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(i.total_sales, 0) AS total_sales,
        COALESCE(i.order_count, 0) AS order_count,
        CASE 
            WHEN i.total_sales >= (SELECT AVG(total_sales) FROM aggregated_sales) THEN 'High Value'
            WHEN i.total_sales >= (SELECT AVG(total_sales) FROM aggregated_sales) * 0.5 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN aggregated_sales i ON c.c_customer_sk = i.ws_bill_cdemo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_stats cs
    WHERE cs.customer_value = 'High Value'
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CASE 
        WHEN r.total_returns IS NOT NULL THEN r.total_returns
        ELSE 0 
    END AS total_returns,
    cs.total_sales,
    cs.order_count,
    th.sales_rank,
    (SELECT COUNT(*) FROM income_hierarchy ih WHERE ih.ib_lower_bound <= cs.total_sales AND ih.ib_upper_bound >= cs.total_sales) AS income_category
FROM customer c
JOIN customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN returns_summary r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN top_customers th ON c.c_customer_sk = th.cs.c_customer_sk
WHERE cs.order_count > 0
ORDER BY cs.total_sales DESC, c.c_last_name, c.c_first_name;
