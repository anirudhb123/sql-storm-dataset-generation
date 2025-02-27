
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT wr.returning_customer_sk) AS total_web_returns,
        COUNT(DISTINCT sr.returning_customer_sk) AS total_store_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AddressStats AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
CombinedStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        as.ca_city,
        as.ca_state,
        cs.total_web_returns,
        cs.total_store_returns,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_web_returns DESC) AS rn
    FROM 
        CustomerStats cs
    JOIN 
        AddressStats as ON cs.c_customer_sk = as.customer_count
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.ca_city,
    c.ca_state,
    c.total_web_returns,
    c.total_store_returns
FROM 
    CombinedStats c
WHERE 
    c.rn <= 5
ORDER BY 
    c.cd_gender, c.total_web_returns DESC;
