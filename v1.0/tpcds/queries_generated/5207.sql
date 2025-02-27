
WITH RevenueData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS month_year
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year >= 2021 AND
        cd.cd_gender = 'F'
    GROUP BY
        ws.web_site_id,
        month_year
),
RankedRevenue AS (
    SELECT
        web_site_id,
        month_year,
        total_revenue,
        total_orders,
        avg_order_value,
        RANK() OVER (PARTITION BY month_year ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        RevenueData
)
SELECT
    rev.web_site_id,
    rev.month_year,
    rev.total_revenue,
    rev.total_orders,
    rev.avg_order_value,
    CASE
        WHEN rev.revenue_rank <= 3 THEN 'Top 3 Revenue'
        ELSE 'Below Top 3'
    END AS revenue_category
FROM
    RankedRevenue rev
WHERE
    rev.total_orders > 100
ORDER BY
    rev.month_year,
    rev.revenue_rank;
