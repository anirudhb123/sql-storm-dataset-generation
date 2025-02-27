
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*)
            AS total_returns,
        SUM(sr_return_amt) 
            AS total_return_amount,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) 
            AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) 
            AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ReturnDetails AS (
    SELECT 
        ri.full_name,
        ri.cd_gender,
        ri.cd_marital_status,
        ri.cd_credit_rating,
        r.total_returns,
        r.total_return_amount
    FROM 
        CustomerInfo ri
    JOIN 
        RankedReturns r ON ri.c_customer_sk = r.sr_customer_sk
    WHERE 
        r.return_rank = 1
)
SELECT 
    cd.cd_gender, 
    COUNT(*) 
        AS number_of_customers,
    AVG(rd.total_return_amount) 
        AS average_return_amount
FROM 
    ReturnDetails rd
JOIN 
    customer_demographics cd ON rd.cd_gender = cd.cd_gender
GROUP BY 
    cd.cd_gender;
