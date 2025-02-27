
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca.ca_state, ', ') AS states,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr.return_amt_inc_tax) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    rc.full_name, 
    rc.cd_gender, 
    rc.cd_marital_status, 
    rc.cities, 
    rc.states, 
    rc.total_returns, 
    rc.total_return_amount
FROM 
    RankedCustomers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_gender, rc.total_return_amount DESC;
