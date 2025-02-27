
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(ca_city) AS max_city,
        MIN(ca_city) AS min_city,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT
        d.d_year,
        SUM(ws.net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.max_city,
    a.min_city,
    a.unique_street_names,
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.total_dependents,
    s.d_year,
    s.total_profit,
    s.total_units_sold
FROM
    AddressStats a
JOIN
    Demographics d ON a.ca_state IN (SELECT DISTINCT ca_state FROM customer_address)
JOIN
    SalesData s ON s.d_year BETWEEN 2020 AND 2023
ORDER BY 
    a.ca_state, d.cd_gender, s.d_year;
