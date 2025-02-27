
WITH AddressDetails AS (
    SELECT
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_suite_number, ', ', ca_zip) AS suite_zip,
        ca_county,
        ca_state,
        ca_country
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM
        web_sales ws
    GROUP BY
        ws.ws_sold_date_sk
),
DateSummary AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        ds.total_quantity,
        ds.total_net_paid
    FROM
        date_dim d
    JOIN
        SalesSummary ds ON d.d_date_sk = ds.ws_sold_date_sk
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    ad.ca_city,
    ad.full_address,
    ad.suite_zip,
    ds.d_date,
    ds.total_quantity,
    ds.total_net_paid
FROM
    CustomerDetails cd
JOIN
    customer_address ad ON cd.c_customer_id = ad.ca_address_id
JOIN
    DateSummary ds ON ad.ca_address_sk = ds.total_quantity
WHERE
    ad.ca_state = 'CA'
ORDER BY
    ds.d_date DESC, cd.c_last_name, cd.c_first_name;
