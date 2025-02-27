
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
ReturnStats AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.min_street_name_length,
    a.max_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.min_purchase_estimate,
    c.max_purchase_estimate,
    r.total_returns,
    r.total_returned_quantity,
    r.total_return_amount
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON 1=1
LEFT JOIN 
    ReturnStats r ON r.sr_returned_date_sk = CURRENT_DATE
ORDER BY 
    a.ca_state, c.cd_gender;
