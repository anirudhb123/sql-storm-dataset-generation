
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM
        customer_demographics cd
    JOIN
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE
        cs.cs_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
),
FinalBenchmark AS (
    SELECT
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_catalog_sales,
        cd.catalog_order_count
    FROM
        CustomerSales cs
    JOIN
        CustomerDemographics cd ON cs.c_customer_id = cd.c_customer_id
)
SELECT
    fb.c_customer_id,
    fb.c_first_name,
    fb.c_last_name,
    fb.total_sales,
    fb.order_count,
    fb.avg_order_value,
    fb.cd_gender,
    fb.cd_marital_status,
    fb.total_catalog_sales,
    fb.catalog_order_count
FROM
    FinalBenchmark fb
ORDER BY
    fb.total_sales DESC
LIMIT 100;
