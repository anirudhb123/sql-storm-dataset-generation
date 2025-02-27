
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.web_site_id, d.d_year, d.d_month_seq
),
SalesRanked AS (
    SELECT 
        web_site_id,
        d_year,
        d_month_seq,
        total_sales,
        total_orders,
        avg_profit,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesData
)
SELECT 
    wr.week,
    sr.web_site_id,
    sr.total_sales,
    sr.total_orders,
    sr.avg_profit
FROM
    (SELECT DISTINCT
        DATE_TRUNC('week', d.d_date) AS week,
        d.d_year,
        d.d_month_seq
     FROM
        date_dim d
     WHERE
        d.d_year BETWEEN 2021 AND 2023
    ) wr
JOIN
    SalesRanked sr ON wr.d_year = sr.d_year AND wr.d_month_seq = sr.d_month_seq
WHERE
    sr.sales_rank <= 5
ORDER BY
    wr.week, sr.total_sales DESC;
