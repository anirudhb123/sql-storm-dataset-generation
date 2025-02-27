
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_quantity,
        cs.total_spent
    FROM customer_demographics cd
    JOIN customer_sales cs ON cs.c_customer_sk = cd.cd_demo_sk
), 
income_summary AS (
    SELECT 
        h.hd_income_band_sk,
        SUM(d.total_spent) AS total_income,
        COUNT(d.cd_demo_sk) AS demographic_count
    FROM household_demographics h
    JOIN demographics d ON h.hd_demo_sk = d.cd_demo_sk
    GROUP BY h.hd_income_band_sk
)
SELECT 
    i.ib_lower_bound,
    i.ib_upper_bound,
    ISNULL(is.total_income, 0) AS total_income,
    ISNULL(is.demographic_count, 0) AS demographic_count
FROM income_band i
LEFT JOIN income_summary is ON i.ib_income_band_sk = is.hd_income_band_sk
ORDER BY i.ib_lower_bound;
