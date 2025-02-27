
WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages,
        COUNT(DISTINCT ws_ship_mode_sk) AS unique_shipping_methods,
        EXTRACT(YEAR FROM dd.d_date) AS sales_year
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        EXTRACT(YEAR FROM dd.d_date)
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_net_paid) AS total_spent,
        SUM(sd.total_orders) AS total_order_count,
        COUNT(DISTINCT sd.ws_bill_customer_sk) AS total_customers
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status
),
IncomeAnalysis AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(DISTINCT hd.hd_demo_sk) AS customer_count,
        SUM(cd.total_spent) AS total_spent
    FROM
        household_demographics hd
    JOIN
        IncomeBand ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN
        CustomerDemographics cd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY
        ib.ib_income_band_sk
)
SELECT
    i.ib_income_band_sk,
    i.customer_count,
    i.total_spent,
    CASE
        WHEN i.total_spent > 10000 THEN 'High Value'
        WHEN i.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    IncomeAnalysis i
ORDER BY
    customer_count DESC;
