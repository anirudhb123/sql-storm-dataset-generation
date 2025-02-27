
WITH AddressStats AS (
    SELECT
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        UPPER(ca_country) AS country_upper,
        LENGTH(ca_zip) AS zip_length
    FROM
        customer_address
    WHERE
        ca_state IN ('CA', 'NY', 'TX')
),
CustomerStats AS (
    SELECT
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM
        customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_demo_sk
),
SalesStats AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid) AS average_net_paid
    FROM
        web_sales
    GROUP BY
        ws_bill_cdemo_sk
),
FinalStats AS (
    SELECT
        a.full_address,
        a.ca_city,
        a.country_upper,
        c.total_customers,
        c.female_count,
        c.male_count,
        s.total_net_profit,
        s.average_net_paid
    FROM
        AddressStats a
    JOIN CustomerStats c ON a.ca_address_id = CAST(c.cd_demo_sk AS CHAR)
    JOIN SalesStats s ON c.cd_demo_sk = s.ws_bill_cdemo_sk
)
SELECT
    FULL_ADDRESS,
    CA_CITY,
    COUNT(FULL_ADDRESS) OVER (PARTITION BY CA_CITY) AS address_count,
    COALESCE(total_customers, 0) AS total_customers,
    COALESCE(female_count, 0) AS female_count,
    COALESCE(male_count, 0) AS male_count,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    COALESCE(average_net_paid, 0) AS average_net_paid
FROM
    FinalStats
ORDER BY
    total_net_profit DESC
LIMIT 100;
