
WITH RECURSIVE MonthlySales AS (
    SELECT
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_month_seq ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        date_dim d
    JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_year = 2022
    GROUP BY
        d.d_month_seq
),
TopProducts AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS product_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_id
    HAVING
        SUM(ws.ws_quantity) > 100
)
SELECT
    d.d_month_seq,
    ms.total_sales,
    COALESCE(tp.total_quantity_sold, 0) AS quantitative_sales,
    CASE
        WHEN ms.sales_rank <= 5 THEN 'Top 5 Sales'
        ELSE 'Others'
    END AS sales_category
FROM
    MonthlySales ms
LEFT JOIN
    TopProducts tp ON ms.d_month_seq = tp.product_rank
ORDER BY
    d_month_seq;
