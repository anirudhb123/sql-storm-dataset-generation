
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_bill_customer_sk
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk,
        s.total_sales,
        s.order_count
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN SalesData s ON c.c_customer_sk = s.customer_sk
    WHERE s.total_sales IS NOT NULL
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(d.cd_gender, 'Unknown') AS gender,
    COALESCE(d.cd_marital_status, 'N/A') AS marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(CASE WHEN s.order_count IS NOT NULL THEN s.total_sales ELSE 0 END) AS total_spent,
    AVG(s.total_sales) OVER (PARTITION BY d.cd_income_band_sk) AS avg_spent_per_income_band,
    COUNT(DISTINCT c.c_customer_sk) OVER (PARTITION BY ib.ib_income_band_sk) AS customer_count_in_band
FROM CustomerWithDemographics c
FULL OUTER JOIN income_band ib ON c.cd_income_band_sk = ib.ib_income_band_sk
WHERE (c.total_sales > 1000 OR c.total_sales IS NULL)
GROUP BY c.c_first_name, c.c_last_name, d.cd_gender, d.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(c.c_customer_sk) > 1
ORDER BY total_spent DESC
LIMIT 50;
