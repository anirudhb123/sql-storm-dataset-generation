
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_street_name, ', ') AS street_names,
        LISTAGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateInfo AS (
    SELECT 
        d_year, 
        d_month_seq, 
        COUNT(*) AS transaction_count
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    ac.address_count,
    ac.street_names,
    ac.street_types,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_dependents,
    cd.average_purchase_estimate,
    di.d_year,
    di.d_month_seq,
    di.transaction_count
FROM 
    AddressCounts ac
JOIN 
    CustomerDemographics cd ON ac.address_count > 100
JOIN 
    DateInfo di ON di.transaction_count > 50
WHERE 
    ac.ca_state = 'CA'
ORDER BY 
    ac.ca_city, di.d_year DESC, di.transaction_count DESC;
