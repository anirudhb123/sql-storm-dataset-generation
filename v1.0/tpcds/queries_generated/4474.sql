
WITH sales_summary AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_price,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS rank_quantity,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 10000 AND 10050
    GROUP BY cs_item_sk
),
top_items AS (
    SELECT
        ss_item_sk,
        total_quantity_sold,
        total_sales,
        avg_price
    FROM sales_summary
    WHERE rank_quantity <= 10 OR rank_sales <= 10
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_gender,
        cd.cd_demo_sk,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_gender,
    ci.cd_marital_status,
    ci.hd_income_band_sk,
    SUM(ts.total_sales) AS total_spent,
    COUNT(ts.total_quantity_sold) AS distinct_items,
    MAX(ts.avg_price) AS max_avg_price
FROM customer_info ci
JOIN top_items ts ON ci.c_customer_sk = ts.cs_item_sk
GROUP BY
    ci.c_customer_sk,
    ci.c_gender,
    ci.cd_marital_status,
    ci.hd_income_band_sk
HAVING
    SUM(ts.total_sales) > 1000 AND COUNT(ts.total_quantity_sold) > 5
ORDER BY total_spent DESC
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
