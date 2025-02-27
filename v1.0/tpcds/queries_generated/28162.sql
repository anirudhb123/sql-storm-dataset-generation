
WITH AddressStats AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name, ', ') AS street_names,
        STRING_AGG(DISTINCT ca_street_type) AS street_types
    FROM customer_address
    GROUP BY ca_city, ca_state
),
CustomerCounts AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.street_names,
    a.street_types,
    c.cd_gender,
    c.cd_marital_status,
    c.customer_count,
    s.total_sales,
    s.order_count
FROM AddressStats AS a
LEFT JOIN CustomerCounts AS c ON a.ca_city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = c.ws_bill_cdemo_sk LIMIT 1) 
LEFT JOIN SalesStats AS s ON c.cd_demo_sk = s.ws_bill_cdemo_sk
ORDER BY a.ca_state, a.ca_city, c.cd_gender;
