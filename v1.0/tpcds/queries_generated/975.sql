
WITH customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_dep_count
),
income_summary AS (
    SELECT
        ib.ib_income_band_sk,
        MIN(total_spent) AS min_spent,
        AVG(total_spent) AS avg_spent,
        MAX(total_spent) AS max_spent
    FROM
        customer_summary cs
    LEFT JOIN income_band ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk
),
order_summary AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_orders DESC) AS order_rank,
        SUM(cs.total_spent) OVER (PARTITION BY cs.hd_income_band_sk) AS income_total_spent
    FROM
        customer_summary cs
)
SELECT
    c.c_customer_sk,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    cs.total_orders,
    cs.total_spent,
    is.min_spent,
    is.avg_spent,
    is.max_spent,
    os.order_rank,
    CASE
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    CASE
        WHEN cs.hd_income_band_sk IS NOT NULL THEN 'Income Band Available'
        ELSE 'Income Band Unknown'
    END AS income_status
FROM
    customer c
LEFT JOIN customer_summary cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN income_summary is ON cs.hd_income_band_sk = is.ib_income_band_sk
LEFT JOIN order_summary os ON cs.c_customer_sk = os.c_customer_sk
WHERE
    (cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary) OR
     cs.total_orders > 5)
AND
    is.min_spent IS NOT NULL
ORDER BY
    cs.total_spent DESC
LIMIT 100;
