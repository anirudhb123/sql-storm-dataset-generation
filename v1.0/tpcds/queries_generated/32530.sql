
WITH RECURSIVE item_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price) > (
        SELECT AVG(ws_sales_price) FROM web_sales
    )
    UNION ALL
    SELECT
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_sales_price) > (
        SELECT AVG(cs_sales_price) FROM catalog_sales
    )
),
top_items AS (
    SELECT
        i_item_sk,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM item_sales
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        dd.d_year,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY dd.d_year DESC) AS year_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
),
customer_spending AS (
    SELECT
        ci.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY ci.c_customer_sk
),
combined_data AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        cs.total_spent,
        cs.orders_count,
        ti.sales_rank
    FROM customer_info ci
    LEFT JOIN customer_spending cs ON ci.c_customer_sk = cs.c_customer_sk
    LEFT JOIN top_items ti ON ti.i_item_sk IN (
        SELECT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = ci.c_customer_sk
    )
    WHERE ci.year_rank = 1
)

SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    COALESCE(cd.total_spent, 0) AS total_spent,
    COALESCE(cd.orders_count, 0) AS orders_count,
    COALESCE(cd.sales_rank, 'N/A') AS sales_rank
FROM combined_data cd
WHERE (cd.sales_rank IS NOT NULL OR cd.total_spent > 1000)
ORDER BY total_spent DESC, sales_rank ASC;
