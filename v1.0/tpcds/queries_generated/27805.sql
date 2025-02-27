
WITH AddressDetails AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        COUNT(*) OVER (PARTITION BY ca_state) AS state_count
    FROM
        customer_address
),
Demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM
        customer_demographics
    GROUP BY
        cd_gender, cd_marital_status, cd_education_status
),
SalesSummary AS (
    SELECT
        CASE
            WHEN ws_sales_price > 100 THEN 'High'
            WHEN ws_sales_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS price_category,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM
        web_sales
    GROUP BY
        CASE
            WHEN ws_sales_price > 100 THEN 'High'
            WHEN ws_sales_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END
)
SELECT
    A.full_address,
    A.ca_city,
    A.ca_state,
    A.ca_zip,
    D.cd_gender,
    D.cd_marital_status,
    D.cd_education_status,
    D.demographic_count,
    S.price_category,
    S.total_quantity,
    S.total_sales
FROM
    AddressDetails A
JOIN
    Demographics D ON D.demographic_count > 0
JOIN
    SalesSummary S ON S.total_quantity > 0
WHERE
    A.state_count > 100
ORDER BY
    A.ca_state, D.cd_gender, S.total_sales DESC;
