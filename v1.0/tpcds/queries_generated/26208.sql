
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses, 
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length, 
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        STRING_AGG(ca_street_name, ', ') AS all_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(c.c_customer_sk) AS customer_count, 
        SUM(cd_dep_count) AS total_dependents, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
ReturnStats AS (
    SELECT 
        sr_returned_date_sk, 
        COUNT(*) AS total_returns, 
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    a.ca_state, 
    a.total_addresses, 
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.total_dependents,
    c.avg_purchase_estimate,
    r.total_returns,
    r.total_return_amount,
    r.total_return_tax
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state = (CASE WHEN c.customer_count IS NOT NULL THEN 'NY' ELSE 'CA' END)  -- Dummy condition for illustration
JOIN 
    ReturnStats r ON r.total_returns > 0
ORDER BY 
    a.total_addresses DESC, 
    c.customer_count DESC;
