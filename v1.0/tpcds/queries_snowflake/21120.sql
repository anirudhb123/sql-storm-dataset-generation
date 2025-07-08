
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        COALESCE(SUM(sr_return_tax), 0) AS total_return_tax 
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_birth_country, 'Unknown') AS birth_country,
        d.total_returns,
        d.total_return_quantity,
        d.total_return_amt,
        d.total_return_tax,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(c.c_birth_country, 'Unknown') ORDER BY d.total_return_amt DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns d ON c.c_customer_sk = d.sr_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
)

SELECT 
    t.birth_country,
    COUNT(CASE WHEN t.total_returns > 0 THEN 1 END) AS customers_with_returns,
    COALESCE(SUM(t.total_return_amt), 0) AS total_return_amount,
    AVG(CASE WHEN t.total_return_quantity > 0 THEN t.total_return_quantity END) AS avg_return_qty,
    LISTAGG(CONCAT(t.c_first_name, ' ', t.c_last_name), ', ') WITHIN GROUP (ORDER BY t.c_first_name) AS customer_names
FROM 
    TopCustomers t
WHERE 
    t.rn <= 5
GROUP BY 
    t.birth_country
HAVING 
    COALESCE(SUM(t.total_return_amt), 0) > 1000
ORDER BY 
    total_return_amount DESC;
