
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        t.t_hour,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        web_sales ws
    JOIN
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        d.d_year = 2022
    GROUP BY
        ws.web_site_id, t.t_hour
),
RankedSales AS (
    SELECT
        web_site_id,
        t_hour,
        total_quantity,
        total_sales,
        avg_net_profit,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesData
)
SELECT
    r.web_site_id,
    r.t_hour,
    r.total_quantity,
    r.total_sales,
    r.avg_net_profit
FROM
    RankedSales r
WHERE
    r.sales_rank <= 5
ORDER BY
    r.web_site_id, r.t_hour;
