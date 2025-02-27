
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), LongStreetNames AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) as full_address,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) as address_length
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city LIKE '%town%'
), AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) as total_returned,
        SUM(sr_return_amt) as total_return_amt,
        COUNT(DISTINCT sr_return_ticket_number) as return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY 
        sr_item_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.c_email_address,
    rc.cd_gender,
    rc.cd_marital_status,
    lsn.full_address,
    lsn.address_length,
    ar.total_returned,
    ar.total_return_amt,
    ar.return_count
FROM 
    RankedCustomers rc
JOIN 
    LongStreetNames lsn ON rc.c_customer_sk = lsn.ca_address_sk
LEFT JOIN 
    AggregateReturns ar ON rc.c_customer_sk = ar.sr_customer_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_gender, ar.total_returned DESC;
