
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM
        web_sales AS ws
    JOIN
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY
        ws.web_site_id
),
TopSalesData AS (
    SELECT
        web_site_id,
        total_quantity,
        total_sales,
        average_net_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesData
)
SELECT
    w.web_site_id,
    w.web_name,
    tsd.total_quantity,
    tsd.total_sales,
    tsd.average_net_profit
FROM
    web_site AS w
JOIN
    TopSalesData AS tsd ON w.web_site_id = tsd.web_site_id
WHERE
    tsd.sales_rank <= 10
ORDER BY
    tsd.total_sales DESC;
