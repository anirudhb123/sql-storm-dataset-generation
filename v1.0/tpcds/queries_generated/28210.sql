
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        COALESCE(cd_dep_count, 0) AS dependency_count,
        COALESCE(cd_dep_employed_count, 0) AS employed_count,
        COALESCE(cd_dep_college_count, 0) AS college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnMetrics AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerPerformance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        r.total_returns,
        r.total_return_amount,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        CustomerDetails d
    JOIN 
        AddressDetails a ON a.ca_address_sk = d.c_customer_sk
    LEFT JOIN 
        ReturnMetrics r ON r.sr_customer_sk = d.c_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.full_address,
    cp.ca_city,
    cp.ca_state,
    cp.ca_zip,
    COALESCE(cp.total_returns, 0) AS returns_count,
    COALESCE(cp.total_return_amount, 0.00) AS returns_sum,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.cd_education_status
FROM 
    CustomerPerformance cp
WHERE 
    cp.total_return_amount > 100 
ORDER BY 
    cp.total_return_amount DESC;
