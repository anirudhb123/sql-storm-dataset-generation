
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(ss.ticket_number) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk > (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY
        ss.sold_date_sk, ss.item_sk
),
CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_gender,
        COALESCE(cd.cd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ss.ticket_number) AS total_orders,
        SUM(ss.ext_sales_price) AS total_spent
    FROM
        customer c
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.customer_sk
    LEFT JOIN
        household_demographics cd ON c.c_current_hdemo_sk = cd.hd_demo_sk
    GROUP BY
        c.c_customer_sk, c_gender, cd.cd_income_band_sk
)
SELECT
    cs.c_customer_sk,
    cs.c_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    AVG(COALESCE(cs.total_spent, 0)) AS avg_spent,
    SUM(COALESCE(cs.total_orders, 0)) AS total_orders,
    MAX(ss.total_sales) AS max_sales,
    MIN(ss.total_sales) AS min_sales
FROM
    CustomerSummary cs
LEFT JOIN
    income_band ib ON cs.income_band = ib.ib_income_band_sk
LEFT JOIN
    SalesCTE ss ON cs.c_customer_sk = ss.item_sk
WHERE
    cs.total_orders > 5
GROUP BY
    cs.c_customer_sk, cs.c_gender, ib.ib_lower_bound, ib.ib_upper_bound
HAVING
    AVG(COALESCE(cs.total_spent, 0)) > 100
ORDER BY
    avg_spent DESC
LIMIT 10;
