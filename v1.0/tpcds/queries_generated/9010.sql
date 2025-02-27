
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
IncomeStats AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        SUM(ws.ws_sales_price) AS total_income_sales
    FROM
        household_demographics hd
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN
        web_sales ws ON hd.hd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY
        hd.hd_demo_sk, ib.ib_income_band_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        ISNULL(is.total_income_sales, 0) AS total_income_sales
    FROM
        CustomerStats cs
    LEFT JOIN
        IncomeStats is ON cs.c_customer_sk = is.hd_demo_sk
    ORDER BY
        total_sales DESC
    LIMIT 100
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    tc.total_orders,
    tc.avg_order_value,
    ROUND(tc.total_income_sales, 2) AS total_income_sales
FROM 
    TopCustomers tc
WHERE 
    tc.total_sales > 1000
