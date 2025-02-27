
WITH SalesData AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.order_number) AS total_web_orders
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.bill_customer_sk
),
CustomerInsights AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(dh.hd_vehicle_count) AS total_vehicles,
        COUNT(DISTINCT dh.hd_income_band_sk) AS unique_income_bands,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_web_orders, 0) AS total_web_orders
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics dh ON c.c_customer_sk = dh.hd_demo_sk
    LEFT JOIN
        SalesData cs ON c.c_customer_sk = cs.bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE 
        WHEN ci.total_web_sales > 1000 THEN 'High Spender'
        WHEN ci.total_web_sales BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spend_category,
    ci.total_web_sales,
    ci.total_web_orders,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_web_sales DESC) AS gender_rank
FROM
    CustomerInsights ci
WHERE
    (ci.total_web_sales IS NOT NULL OR ci.total_web_orders > 0)
ORDER BY
    ci.total_web_sales DESC;
