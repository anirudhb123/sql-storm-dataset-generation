
WITH SalesData AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        AVG(ws.sales_price) AS avg_sales_price,
        MAX(ws.shipping_cost) AS max_shipping_cost
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY
        ws.bill_customer_sk
),
DemographicData AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(sd.total_sales) AS total_sales
    FROM
        customer_demographics cd
    LEFT JOIN
        SalesData sd ON cd.cd_demo_sk = sd.bill_customer_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_marital_status
)
SELECT
    dd.cd_marital_status,
    dd.customer_count,
    COALESCE(dd.total_sales, 0) AS total_sales,
    ROUND((dd.total_sales / NULLIF(dd.customer_count, 0)), 2) AS avg_sales_per_customer
FROM
    DemographicData dd
ORDER BY
    total_sales DESC;
