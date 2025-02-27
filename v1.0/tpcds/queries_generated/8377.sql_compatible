
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY
        ws.web_site_sk
),
TopWebSites AS (
    SELECT
        web_site_sk,
        total_quantity,
        total_revenue
    FROM
        RankedSales
    WHERE
        revenue_rank <= 10
)
SELECT
    w.warehouse_id,
    w.warehouse_name,
    tws.total_quantity,
    tws.total_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM
    TopWebSites tws
JOIN
    warehouse w ON tws.web_site_sk = w.w_warehouse_sk
JOIN
    web_sales ws ON tws.web_site_sk = ws.ws_web_site_sk
GROUP BY
    w.warehouse_id,
    w.warehouse_name,
    tws.total_quantity,
    tws.total_revenue
ORDER BY
    tws.total_revenue DESC;
