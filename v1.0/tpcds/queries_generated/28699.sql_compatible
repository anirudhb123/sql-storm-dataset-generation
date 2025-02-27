
WITH AddressAggregates AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS distinct_address_count,
        STRING_AGG(ca_street_name, ', ') AS all_street_names
    FROM
        customer_address
    GROUP BY
        ca_state
),
DemographicsAnalysis AS (
    SELECT
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM
        customer 
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
),
DateInfo AS (
    SELECT
        d_year,
        STRING_AGG(DISTINCT d_day_name, ', ') AS unique_days,
        COUNT(*) AS total_dates
    FROM
        date_dim
    GROUP BY
        d_year
)
SELECT
    aa.ca_state,
    aa.distinct_address_count,
    aa.all_street_names,
    da.cd_gender,
    da.customer_count,
    da.avg_purchase_estimate,
    da.marital_statuses,
    di.d_year,
    di.unique_days,
    di.total_dates
FROM
    AddressAggregates aa
JOIN
    DemographicsAnalysis da ON aa.distinct_address_count > 100
JOIN
    DateInfo di ON di.total_dates > 2000
ORDER BY
    aa.ca_state, da.customer_count DESC;
