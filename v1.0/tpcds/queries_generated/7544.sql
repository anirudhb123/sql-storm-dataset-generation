
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_gender AS customer_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_gender
),
demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    cs.customer_gender,
    d.cd_marital_status,
    d.hd_buy_potential,
    COUNT(cs.c_customer_sk) AS customer_count,
    AVG(cs.total_sales) AS avg_sales,
    MAX(cs.total_sales) AS max_sales,
    MIN(cs.total_sales) AS min_sales
FROM
    customer_sales cs
JOIN
    demographics d ON cs.c_customer_sk = d.cd_demo_sk
WHERE
    cs.total_sales > 1000
GROUP BY
    cs.customer_gender,
    d.cd_marital_status,
    d.hd_buy_potential
ORDER BY
    customer_count DESC, avg_sales DESC;
