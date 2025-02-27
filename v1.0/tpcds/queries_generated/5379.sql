
WITH CustomerInfo AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.order_count
    FROM
        CustomerInfo ci
    LEFT JOIN
        SalesData si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT
    c.c_gender,
    COUNT(c.c_gender) AS customer_count,
    AVG(cs.total_sales) AS avg_sales,
    AVG(cs.order_count) AS avg_orders,
    MAX(cs.total_sales) AS max_sales,
    MIN(cs.total_sales) AS min_sales
FROM
    CustomerSales cs
JOIN
    CustomerInfo c ON cs.c_customer_id = c.c_customer_id
GROUP BY
    c.c_gender
ORDER BY
    customer_count DESC;
