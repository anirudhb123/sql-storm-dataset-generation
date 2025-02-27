
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        c_customer_sk
    FROM
        RankedCustomers
    WHERE
        purchase_rank <= 5
),
CustomerAddresses AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerLocationData AS (
    SELECT
        tc.full_name,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_education_status,
        tc.cd_purchase_estimate,
        cl.ca_city,
        cl.ca_state,
        cl.ca_country
    FROM
        TopCustomers tc
    JOIN
        CustomerAddresses cl ON tc.c_customer_sk = cl.c_customer_sk
)
SELECT
    cl.cd_gender,
    cl.cd_marital_status,
    cl.cd_education_status,
    COUNT(*) AS customer_count,
    ROUND(AVG(cl.cd_purchase_estimate), 2) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(cl.ca_city, ', ', cl.ca_state, ', ', cl.ca_country), '; ') AS customer_locations
FROM
    CustomerLocationData cl
GROUP BY
    cl.cd_gender,
    cl.cd_marital_status,
    cl.cd_education_status
ORDER BY
    customer_count DESC;
