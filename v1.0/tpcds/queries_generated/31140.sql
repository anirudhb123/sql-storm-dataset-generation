
WITH RECURSIVE sales_trend AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
    UNION ALL
    SELECT
        ds.d_date_sk,
        COALESCE(st.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ds.d_date_sk ORDER BY ds.d_date_sk) AS sales_rank
    FROM
        date_dim ds
    LEFT JOIN sales_trend st ON ds.d_date_sk = DATE_ADD(st.ws_sold_date_sk, INTERVAL 1 DAY)
    WHERE
        ds.d_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographic_sales AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_spent) AS total_demographic_spent
    FROM
        customer_demographics cd
    LEFT JOIN customer_sales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT
        dt.d_date AS sale_date,
        st.total_sales AS daily_sales,
        COALESCE(ds.total_demographic_spent, 0) AS demographic_sales,
        RANK() OVER (ORDER BY dt.d_date) AS sales_rank
    FROM
        date_dim dt
    LEFT JOIN sales_trend st ON dt.d_date_sk = st.ws_sold_date_sk
    LEFT JOIN demographic_sales ds ON dt.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_sold_date_sk <= dt.d_date_sk)
)
SELECT
    ss.sale_date,
    ss.daily_sales,
    ss.demographic_sales,
    CASE
        WHEN ss.demographic_sales > 1000 THEN 'High'
        WHEN ss.demographic_sales > 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    CASE
        WHEN ss.daily_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM
    sales_summary ss
WHERE
    ss.daily_sales IS NOT NULL
ORDER BY
    ss.sale_date DESC
LIMIT 100;
