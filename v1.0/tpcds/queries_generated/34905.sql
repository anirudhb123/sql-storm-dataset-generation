
WITH RECURSIVE sales_date AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2022
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq
    FROM date_dim d
    JOIN sales_date sd ON d.d_date_sk = sd.d_date_sk + 1
),
sales_summary AS (
    SELECT 
        d_year,
        MONTH(d_date) AS month,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales
    FROM sales_date sd
    JOIN web_sales ws ON sd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d_year, MONTH(d_date),
    HAVING COUNT(ws_order_number) > 10
),
customer_incomes AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, ib.ib_income_band_sk
),
ranked_sales AS (
    SELECT 
        month,
        total_sales,
        RANK() OVER (PARTITION BY month ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    cs.year,
    cs.month,
    cs.total_orders,
    cs.total_sales,
    cs.avg_sales,
    ci.ib_income_band_sk,
    ci.customer_count
FROM ranked_sales cs
LEFT JOIN customer_incomes ci ON cs.month = MONTH(CURDATE())
WHERE cs.sales_rank <= 5
ORDER BY cs.total_sales DESC;
