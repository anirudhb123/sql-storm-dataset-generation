
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(ca_street_name, ', ') AS street_names,
        SUM(CASE WHEN ca_suite_number IS NOT NULL THEN 1 ELSE 0 END) AS suite_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.street_names,
    a.suite_count,
    c.cd_gender,
    c.cd_marital_status,
    c.customer_count,
    c.avg_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.total_transactions
FROM 
    AddressSummary a
JOIN 
    CustomerDemographics c ON a.ca_state = 'CA'
JOIN 
    SalesSummary s ON s.d_year = 2023
ORDER BY 
    a.unique_addresses DESC, 
    c.customer_count DESC;
