
WITH sales_data AS (
    SELECT
        ws.web_site_id,
        d.d_year AS sales_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.web_site_id,
        d.d_year
),
avg_profit AS (
    SELECT
        sales_year,
        AVG(total_profit) AS avg_profit_per_site
    FROM
        sales_data
    GROUP BY
        sales_year
),
top_web_sites AS (
    SELECT
        sales_year,
        web_site_id,
        total_profit,
        total_orders,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_profit DESC) AS rank
    FROM
        sales_data
)
SELECT 
    tws.sales_year,
    tws.web_site_id,
    tws.total_profit,
    tws.total_orders,
    ap.avg_profit_per_site
FROM 
    top_web_sites AS tws
JOIN 
    avg_profit AS ap ON tws.sales_year = ap.sales_year
WHERE 
    tws.rank <= 3
ORDER BY 
    tws.sales_year, tws.rank;
