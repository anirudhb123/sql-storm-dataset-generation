
WITH RECURSIVE sales_trends AS (
    SELECT
        d.d_date AS sale_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_date
),
top_sales AS (
    SELECT
        sale_date,
        total_sales,
        sales_rank
    FROM
        sales_trends
    WHERE
        sales_rank <= 10
)
SELECT
    sa.sale_date,
    COALESCE(st.total_sales, 0) AS web_sales_total,
    COALESCE(sr.total_sales, 0) AS store_sales_total,
    (COALESCE(st.total_sales, 0) + COALESCE(sr.total_sales, 0)) AS combined_sales_total,
    CASE
        WHEN COALESCE(st.total_sales, 0) > COALESCE(sr.total_sales, 0) THEN 'Web Sales Dominant'
        WHEN COALESCE(sr.total_sales, 0) > COALESCE(st.total_sales, 0) THEN 'Store Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance
FROM
    top_sales sa
LEFT JOIN (
    SELECT
        d.d_date AS sale_date,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM
        date_dim d
    LEFT JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_date
) sr ON sa.sale_date = sr.sale_date
LEFT JOIN (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    GROUP BY
        ws.ws_sold_date_sk
) st ON sa.sale_date = (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = st.ws_sold_date_sk)
ORDER BY
    sa.sale_date;
