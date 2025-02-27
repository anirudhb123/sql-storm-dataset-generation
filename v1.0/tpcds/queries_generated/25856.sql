
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        SUBSTRING_WS('-', ca.ca_street_name) AS street_name_component
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    ORDER BY 
        ca.ca_city, full_name
),
AggregateIncome AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    ai.customer_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    AggregateIncome ai ON 1=1
FETCH FIRST 100 ROWS ONLY;
