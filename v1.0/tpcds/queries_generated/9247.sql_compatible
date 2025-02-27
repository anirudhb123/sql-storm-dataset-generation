
WITH CustomerStats AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
IncomeStats AS (
    SELECT
        h.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_item_sk) AS total_items_sold
    FROM
        household_demographics h
    JOIN store_sales ss ON h.hd_demo_sk = ss.ss_customer_sk
    GROUP BY
        h.hd_income_band_sk
)

SELECT
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_customers,
    cs.total_sales,
    cs.avg_sales_price,
    cs.total_quantity_sold,
    is.total_net_profit,
    is.total_items_sold
FROM
    CustomerStats cs
LEFT JOIN IncomeStats is ON cs.total_customers > 0 AND is.total_items_sold > 0
ORDER BY
    cs.total_sales DESC,
    cs.total_quantity_sold DESC;
