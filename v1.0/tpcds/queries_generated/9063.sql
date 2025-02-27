
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        wd.d_month_seq,
        c.cd_gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    WHERE
        wd.d_year = 2022
    GROUP BY
        wd.d_month_seq,
        c.cd_gender
),
MonthlySales AS (
    SELECT
        d_month_seq,
        cd_gender,
        total_sales,
        order_count,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesData
)
SELECT
    ms.d_month_seq,
    ms.cd_gender,
    ms.total_sales,
    ms.order_count
FROM
    MonthlySales ms
WHERE
    ms.sales_rank <= 5
ORDER BY
    ms.d_month_seq,
    ms.cd_gender;
