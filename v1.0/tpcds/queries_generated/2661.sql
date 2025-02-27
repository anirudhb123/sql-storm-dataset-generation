
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
sales_by_gender AS (
    SELECT
        cd.cd_gender,
        SUM(cs.total_sales) AS gender_sales,
        COUNT(cs.c_customer_id) AS customer_count,
        AVG(cs.avg_net_paid) AS avg_net_per_customer
    FROM
        customer_sales cs
    JOIN
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_id, i.i_item_desc
    ORDER BY
        total_sales DESC
    LIMIT 10
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    coalesce(sbg.gender_sales, 0) AS total_sales_by_gender,
    (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk) AS order_count,
    (SELECT COUNT(ireturns.wr_item_sk) FROM web_returns ireturns WHERE ireturns.wr_returning_customer_sk = ci.c_customer_sk) AS return_count,
    ti.i_item_desc,
    ti.total_quantity_sold
FROM
    customer c AS ci
LEFT JOIN
    sales_by_gender sbg ON ci.c_customer_id = sbg.cd_gender
JOIN
    top_items ti ON ti.total_quantity_sold > 0
WHERE
    (ci.c_birth_year IS NOT NULL OR ci.c_birth_month IS NULL OR ci.c_birth_day IS NULL)
    AND ci.c_current_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM household_demographics
        WHERE hd_income_band_sk IN (
            SELECT ib_income_band_sk
            FROM income_band
            WHERE (ib_lower_bound BETWEEN 30000 AND 70000) 
            OR (ib_upper_bound IS NULL)
        )
    )
ORDER BY
    total_sales_by_gender DESC, ci.c_first_name, ci.c_last_name;
