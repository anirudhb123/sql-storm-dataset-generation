
WITH ranked_sales AS (
    SELECT
        ws.web_site_id,
        COUNT(ws.order_number) AS total_sales,
        SUM(ws.ext_sales_price) AS total_revenue,
        SUM(ws.ext_tax) AS total_tax,
        SUM(ws.ext_ship_cost) AS total_shipping_cost,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.sold_date_sk = d.date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.web_site_id
),
customer_summary AS (
    SELECT
        c.customer_id,
        cd.gender,
        cd.marital_status,
        SUM(ws.net_paid) AS total_spent,
        COUNT(ws.order_number) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    JOIN
        web_sales ws ON c.customer_sk = ws.bill_customer_sk
    WHERE
        c.first_shipto_date_sk IS NOT NULL
    GROUP BY
        c.customer_id, cd.gender, cd.marital_status
)
SELECT
    rs.web_site_id,
    rs.total_sales,
    rs.total_revenue,
    cs.gender,
    cs.marital_status,
    AVG(cs.total_spent) AS avg_spent,
    COUNT(DISTINCT cs.customer_id) AS unique_customers
FROM
    ranked_sales rs
JOIN
    customer_summary cs ON rs.total_sales > 100
GROUP BY
    rs.web_site_id, rs.total_sales, rs.total_revenue, cs.gender, cs.marital_status
HAVING
    COUNT(cs.customer_id) > 10
ORDER BY
    rs.total_revenue DESC
LIMIT 10;
