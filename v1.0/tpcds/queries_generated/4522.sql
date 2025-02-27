
WITH yearly_sales AS (
    SELECT
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year
),
income_distribution AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY ib.ib_income_band_sk
),
ranked_sales AS (
    SELECT
        y.d_year,
        y.total_web_sales,
        y.total_catalog_sales,
        y.total_store_sales,
        RANK() OVER (ORDER BY (y.total_web_sales + y.total_catalog_sales + y.total_store_sales) DESC) AS sales_rank
    FROM yearly_sales y
),
customer_stats AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_purchases,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_purchases
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
)
SELECT
    y.d_year,
    COALESCE(y.total_web_sales, 0) AS total_web_sales,
    COALESCE(y.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(y.total_store_sales, 0) AS total_store_sales,
    i.customer_count AS income_band_customers,
    cs.cd_gender,
    MAX(cs.total_store_purchases) AS max_store_purchases,
    AVG(cs.total_web_purchases) AS avg_web_purchases,
    SUM(CASE WHEN cs.total_catalog_purchases > 0 THEN 1 ELSE 0 END) AS active_catalog_customers
FROM ranked_sales y
LEFT JOIN income_distribution i ON 1=1
LEFT JOIN customer_stats cs ON y.d_year IN (SELECT d_year FROM yearly_sales)
GROUP BY y.d_year, i.customer_count, cs.cd_gender
ORDER BY y.d_year DESC, total_web_sales DESC;
