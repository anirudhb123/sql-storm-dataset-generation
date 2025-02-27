
WITH customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
top_customers AS (
    SELECT *
    FROM customer_summary
    WHERE gender_rank <= 5
),
high_income_customers AS (
    SELECT
        h.hd_demo_sk,
        h.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_spending
    FROM
        household_demographics h
        JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY h.hd_demo_sk, h.hd_income_band_sk
    HAVING SUM(ws.ws_net_paid) > (SELECT AVG(total_spent) FROM customer_summary)
),
final_summary AS (
    SELECT
        t.first_name,
        t.last_name,
        ti.total_spent,
        t.gender,
        i.ib_income_band_sk
    FROM
        top_customers t
        LEFT JOIN high_income_customers ti ON t.c_customer_sk = ti.hd_demo_sk
        LEFT JOIN income_band i ON ti.hd_income_band_sk = i.ib_income_band_sk
)
SELECT
    final.*,
    CASE
        WHEN final.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Total Spent: ' || ROUND(final.total_spent, 2)::text
    END AS purchase_status
FROM
    final_summary final
ORDER BY
    final.total_spent DESC NULLS LAST;
