
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 0
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_brackets ibr ON ib.ib_income_band_sk = ibr.ib_income_band_sk + 1
)
, customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        MAX(ws.ws_sold_date_sk) AS last_purchase,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        CASE 
            WHEN SUM(ws.ws_ext_sales_price) IS NULL THEN 'No Sales'
            WHEN SUM(ws.ws_ext_sales_price) > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT
    cs.customer_name,
    cs.total_orders,
    cs.total_sales,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.customer_value,
    DENSE_RANK() OVER (PARTITION BY cs.customer_value ORDER BY cs.total_sales DESC) AS sales_rank
FROM customer_stats cs
JOIN household_demographics hd ON hd.hd_demo_sk = cs.c_customer_sk
LEFT JOIN income_brackets ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE (cs.total_orders > 0 OR cs.total_sales > 0)
AND (cs.customer_value IS NOT NULL)
ORDER BY cs.customer_value, sales_rank
LIMIT 100;
