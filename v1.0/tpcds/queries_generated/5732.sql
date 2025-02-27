
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_quantity,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    WHERE
        sd.total_quantity > 100
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F'
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ts.total_sales,
    ts.total_quantity
FROM
    TopSales ts
JOIN
    CustomerInfo ci ON ci.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk
        FROM web_sales ws
        JOIN TopSales ts2 ON ws.ws_item_sk = ts2.ws_item_sk
        WHERE ts2.sales_rank <= 10
    )
WHERE
    ts.total_sales > 5000
ORDER BY
    ts.total_sales DESC;
