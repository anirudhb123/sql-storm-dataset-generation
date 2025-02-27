
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerDemographics cd
    JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returns > 0 AND cd.cd_purchase_estimate > 5000
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    cr.total_returns,
    cr.total_return_value,
    CASE 
        WHEN cd.gender_rank <= 5 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS customer_category
FROM 
    HighSpenders hs
JOIN 
    customer c ON hs.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerReturns cr ON cr.sr_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
ORDER BY 
    cr.total_return_value DESC
LIMIT 100;
