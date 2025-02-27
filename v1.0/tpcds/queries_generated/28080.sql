
WITH AddressDetails AS (
    SELECT
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types,
        STRING_AGG(DISTINCT ca_street_name, '; ') AS street_names
    FROM
        customer_address
    GROUP BY
        ca_state, ca_city
),
Demographics AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
SalesDetails AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    WHERE
        ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        ws_ship_date_sk
)
SELECT
    ad.ca_state,
    ad.ca_city,
    ad.address_count,
    ad.street_types,
    ad.street_names,
    d.cd_gender,
    d.demographic_count,
    d.total_dependents,
    d.employed_dependents,
    d.college_dependents,
    s.ws_ship_date_sk,
    s.total_sales,
    s.total_net_profit
FROM
    AddressDetails ad
JOIN
    Demographics d ON ad.ca_city = d.cd_gender  -- Assuming a fictional join condition for demonstration
JOIN
    SalesDetails s ON s.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)  -- For the most recent sales date
ORDER BY
    ad.ca_state, ad.ca_city;
