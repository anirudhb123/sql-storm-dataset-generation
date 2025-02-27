
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DATE(DATEADD(DAY, 1, dd.d_date)) AS sales_date
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
        (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
    GROUP BY
        ws.ws_item_sk, DATE(DATEADD(DAY, 1, dd.d_date))
)

SELECT
    sd.ws_item_sk,
    i.i_item_desc,
    i.i_brand,
    sd.total_quantity,
    sd.total_sales,
    sd.avg_net_profit,
    RANK() OVER (PARTITION BY sd.sales_date ORDER BY sd.total_sales DESC) AS sales_rank
FROM
    SalesData sd
JOIN
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE
    sd.total_sales > 1000
ORDER BY
    sd.sales_date, sales_rank;
