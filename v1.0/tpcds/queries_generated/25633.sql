
WITH AddressDetails AS (
    SELECT
        ca.address_sk,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        ca.city,
        ca.state,
        ca.zip,
        ca.country
    FROM
        customer_address ca
),
CustomerDetails AS (
    SELECT
        c.customer_sk,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
),
SalesData AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(ws.order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.bill_customer_sk
),
CustomerBenchmark AS (
    SELECT
        cd.full_name,
        ad.full_address,
        ad.city,
        ad.state,
        ad.zip,
        ad.country,
        sd.total_sales,
        sd.order_count
    FROM
        CustomerDetails cd
    JOIN
        AddressDetails ad ON cd.customer_sk = ad.address_sk
    LEFT JOIN
        SalesData sd ON cd.customer_sk = sd.bill_customer_sk
)
SELECT
    full_name,
    full_address,
    city,
    state,
    zip,
    country,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    CASE
        WHEN COALESCE(total_sales, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    CustomerBenchmark
WHERE
    city IS NOT NULL
ORDER BY
    total_sales DESC, full_name;
