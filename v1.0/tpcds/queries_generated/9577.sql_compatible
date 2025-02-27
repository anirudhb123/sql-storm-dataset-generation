
WITH sales_summary AS (
    SELECT
        ws.web_site_id,
        cd.gender,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_paid) AS total_revenue,
        SUM(ws.quantity) AS total_quantity_sold
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    JOIN
        date_dim d ON ws.sold_date_sk = d.date_sk
    WHERE
        d.year = 2023
        AND d.month_seq IN (5, 6)
    GROUP BY
        ws.web_site_id, cd.gender
),
top_sales AS (
    SELECT
        web_site_id,
        gender,
        total_orders,
        total_revenue,
        total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        sales_summary
)
SELECT
    t.web_site_id,
    t.gender,
    t.total_orders,
    t.total_revenue,
    t.total_quantity_sold
FROM
    top_sales t
WHERE
    t.revenue_rank <= 5
ORDER BY
    t.gender, t.total_revenue DESC;
