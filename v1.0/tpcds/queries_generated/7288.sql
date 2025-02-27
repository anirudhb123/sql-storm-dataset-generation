
WITH ranked_sales AS (
    SELECT
        s.ss_sold_date_sk,
        s.ss_item_sk,
        i.i_item_desc,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_quantity) DESC) AS rank
    FROM
        store_sales s
    JOIN
        item i ON s.ss_item_sk = i.i_item_sk
    WHERE
        s.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY
        s.ss_sold_date_sk, s.ss_item_sk, i.i_item_desc
),
top_selling_items AS (
    SELECT
        rs.ss_item_sk,
        rs.i_item_desc,
        rs.total_quantity,
        rs.total_net_paid
    FROM
        ranked_sales rs
    WHERE
        rs.rank <= 10
),
demographics_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ts.total_quantity) AS total_items_sold,
        SUM(ts.total_net_paid) AS total_revenue
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        top_selling_items ts ON ts.ss_item_sk IN (SELECT ss_item_sk FROM store_sales WHERE ss_sold_date_sk BETWEEN ts.sold_date_start AND ts.sold_date_end)
    GROUP BY
        cd.cd_gender
)
SELECT
    cd.cd_gender,
    ds.customer_count,
    ds.total_items_sold,
    ds.total_revenue,
    (ds.total_revenue / NULLIF(ds.total_items_sold, 0)) AS average_revenue_per_item
FROM
    demographics_summary ds
JOIN
    customer_demographics cd ON ds.customer_count = cd.cd_demo_sk
ORDER BY
    total_revenue DESC;
