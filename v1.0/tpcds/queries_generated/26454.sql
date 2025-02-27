
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.return_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amt,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities_returned_from
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, full_name, cd.cd_gender, cd.cd_marital_status
),
ReturnSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS num_customers,
        SUM(total_returns) AS total_returns,
        SUM(total_returned_amt) AS total_returned_amt,
        AVG(avg_return_quantity) AS avg_return_quantity
    FROM
        CustomerStats
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    num_customers,
    total_returns,
    total_returned_amt,
    avg_return_quantity,
    CASE WHEN total_returns > 0 THEN (total_returned_amt / total_returns) ELSE 0 END AS avg_return_value
FROM 
    ReturnSummary
ORDER BY
    cd_gender, cd_marital_status;
