
WITH RECURSIVE recent_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_month
    FROM customer
    WHERE c_first_shipto_date_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month
    FROM customer c
    JOIN recent_customers rc ON c.c_current_addr_sk = rc.c_customer_sk
),
monthly_sales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY dd.d_year, dd.d_month_seq
),
demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY cd.cd_gender
),
high_income_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, hd.hd_income_band_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (
        SELECT ib.ib_income_band_sk
        FROM income_band ib
        WHERE ib.ib_upper_bound > 100000
    )
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    SUM(ms.total_sales) AS monthly_total_sales,
    COALESCE(dg.customer_count, 0) AS gender_based_customer_count,
    CASE WHEN COUNT(DISTINCT ic.hd_income_band_sk) > 0 THEN 'High Income' ELSE 'Other' END AS income_category
FROM recent_customers rc
LEFT JOIN monthly_sales ms ON rc.c_birth_month = ms.d_month_seq
LEFT JOIN demographics dg ON dg.cd_gender = 'F'
LEFT JOIN high_income_customers ic ON rc.c_customer_sk = ic.c_customer_sk
GROUP BY rc.c_first_name, rc.c_last_name, dg.customer_count
ORDER BY monthly_total_sales DESC, rc.c_last_name ASC;
