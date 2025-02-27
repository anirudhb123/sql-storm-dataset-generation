
WITH AddressAggregation AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM
        customer_address
    GROUP BY
        ca_state
),
CustomerDemographics AS (
    SELECT
        cd_gender,
        COUNT(c.customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dep_count,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_gender
),
DateAggregation AS (
    SELECT
        d_year,
        COUNT(ws_order_number) AS orders_count,
        SUM(ws_net_paid) AS total_sales,
        STRING_AGG(DISTINCT d_day_name, ', ') AS unique_days
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        d_year
),
FinalBenchmark AS (
    SELECT
        aa.ca_state,
        aa.address_count,
        aa.cities,
        cd.cd_gender,
        cd.customer_count,
        cd.avg_dep_count,
        cd.marital_statuses,
        da.d_year,
        da.orders_count,
        da.total_sales,
        da.unique_days
    FROM
        AddressAggregation aa
    JOIN
        CustomerDemographics cd ON 1=1
    JOIN
        DateAggregation da ON 1=1
)
SELECT
    ca_state,
    address_count,
    cities,
    cd_gender,
    customer_count,
    avg_dep_count,
    marital_statuses,
    d_year,
    orders_count,
    total_sales,
    unique_days
FROM
    FinalBenchmark
ORDER BY
    ca_state, cd_gender, d_year;
