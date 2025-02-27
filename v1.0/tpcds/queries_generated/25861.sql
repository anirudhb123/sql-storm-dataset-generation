
WITH AddressComponents AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ac.full_address,
        ac.ca_city,
        ac.ca_state
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
),
SalesSummary AS (
    SELECT
        s.ss_store_sk,
        COUNT(s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_paid) AS total_net_paid,
        SUM(s.ss_net_profit) AS total_net_profit
    FROM
        store_sales s
    GROUP BY
        s.ss_store_sk
)
SELECT
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ss.total_sales,
    ss.total_net_paid,
    ss.total_net_profit
FROM
    CustomerDetails cd
JOIN
    SalesSummary ss ON cd.c_customer_sk = ss.ss_store_sk -- Assuming correlation with store_sk
WHERE
    cd.cd_purchase_estimate > 500
ORDER BY
    ss.total_net_profit DESC
LIMIT 100;
