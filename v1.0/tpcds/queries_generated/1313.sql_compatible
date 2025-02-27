
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        dd.d_year,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year >= 2020
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk, 
        dd.d_year
),
income_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        SUM(ci.total_spent) AS total_income
    FROM customer_info ci
    JOIN household_demographics hd ON ci.cd_income_band_sk = hd.hd_income_band_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
ranked_income AS (
    SELECT 
        isum.ib_income_band_sk,
        isum.customer_count,
        isum.total_income,
        RANK() OVER (ORDER BY isum.total_income DESC) AS income_rank
    FROM income_summary isum
)
SELECT 
    ri.income_rank,
    ri.ib_income_band_sk,
    ri.customer_count,
    ri.total_income,
    COALESCE((SELECT COUNT(*) 
               FROM store_sales ss 
               WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2021)
               AND ss.ss_net_paid > 100), 0) AS high_value_sales_count,
    COALESCE((SELECT COUNT(*) 
               FROM catalog_sales cs 
               WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2021)
               AND cs.cs_net_paid > 100), 0) AS catalog_high_value_sales_count
FROM ranked_income ri
WHERE ri.income_rank <= 5
ORDER BY ri.income_rank;
