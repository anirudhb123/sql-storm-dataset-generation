
WITH monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year,
        d.d_month_seq
),
customer_statistics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(MAX(hd.hd_income_band_sk), 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender
),
high_value_customers AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY c_gender ORDER BY order_count DESC) as customer_rank
    FROM
        customer_statistics
    WHERE
        order_count > 5 
),
monthly_avg_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        AVG(total_sales) AS avg_monthly_sales
    FROM
        monthly_sales
    GROUP BY
        d.d_year,
        d.d_month_seq
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.gender,
    v.income_band,
    monthly_avg.avg_monthly_sales,
    COALESCE((SELECT SUM(ss_ext_sales_price)
               FROM store_sales
               WHERE ss_customer_sk = c.c_customer_sk
                 AND ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)), 0) AS total_store_sales,
    CASE
        WHEN customer_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM
    high_value_customers c
LEFT JOIN income_band v ON c.income_band = v.ib_income_band_sk
INNER JOIN monthly_avg_sales monthly_avg ON c.c_first_name LIKE CONCAT('%', monthly_avg.d_year, '%')
WHERE
    (c.order_count * 1.5 + SUM(CASE WHEN c.gender = 'F' THEN 1 ELSE 0 END) > 10)
    AND (monthly_avg.avg_monthly_sales IS NOT NULL OR c.order_count > 10)
ORDER BY
    total_store_sales DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
