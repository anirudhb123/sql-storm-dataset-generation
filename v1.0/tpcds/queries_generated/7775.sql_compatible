
WITH SalesData AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    LEFT JOIN
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    LEFT JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY
        ws.web_site_sk
),
TopSites AS (
    SELECT
        web_site_sk,
        total_sales,
        total_orders,
        avg_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesData
)
SELECT
    ts.web_site_sk,
    w.web_name,
    ts.total_sales,
    ts.total_orders,
    ts.avg_profit,
    ts.sales_rank
FROM
    TopSites ts
JOIN
    web_site w ON ts.web_site_sk = w.web_site_sk
WHERE
    ts.sales_rank <= 10
ORDER BY
    ts.total_sales DESC;
