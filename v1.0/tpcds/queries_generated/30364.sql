
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        0 AS level,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        sh.level + 1,
        COALESCE(SUM(ws.ws_sales_price), 0) + sh.total_sales
    FROM sales_hierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.level
),
daily_totals AS (
    SELECT 
        dd.d_date,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM date_dim dd
    LEFT JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_date
),
customer_incomes AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_demo_sk, hd.hd_income_band_sk
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales AS customer_total_sales,
    di.d_date,
    dt.total_sales AS daily_sales,
    dt.total_profit AS daily_profit,
    ci.total_spent AS income_total_spent,
    ci.order_count AS income_order_count
FROM sales_hierarchy sh
JOIN daily_totals dt ON dt.total_sales > 1000 -- only interested in high sales days
JOIN customer_incomes ci ON ci.hd_income_band_sk = 
    (SELECT ib.ib_income_band_sk FROM income_band ib WHERE ib.ib_lower_bound <= ci.total_spent AND ci.total_spent <= ib.ib_upper_bound)
ORDER BY sh.total_sales DESC, dt.d_date DESC
LIMIT 100;
