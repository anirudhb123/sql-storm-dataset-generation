
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.warehouse_sk,
        CAST(ws.ws_sales_price * ws.ws_quantity AS DECIMAL(10,2)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
latest_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        SUM(cs.total_sales) AS total_sales,
        COUNT(*) AS sales_count
    FROM customer_sales cs
    WHERE cs.sales_rank <= 5
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name
),
income_summary AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.total_sales) AS total_income
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN latest_sales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    isummary.ib_lower_bound,
    isummary.ib_upper_bound,
    COUNT(*) AS customer_count,
    SUM(isummary.total_income) AS total_income,
    MAX(isummary.total_income) AS max_income,
    COALESCE(MIN(isummary.total_income), 0) AS min_income,
    (SELECT AVG(total_income) FROM income_summary) AS avg_income,
    RANK() OVER (ORDER BY SUM(isummary.total_income) DESC) AS income_rank
FROM income_summary isummary
GROUP BY isummary.ib_lower_bound, isummary.ib_upper_bound
HAVING SUM(isummary.total_income) > (SELECT AVG(total_income) FROM income_summary WHERE total_income IS NOT NULL)
ORDER BY income_rank
LIMIT 10;
