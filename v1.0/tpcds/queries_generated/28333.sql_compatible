
WITH CustomerReturnSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_quantity) AS total_return_quantity,
        SUM(sr.return_amt) AS total_returned_amount,
        SUM(sr.return_tax) AS total_returned_tax,
        STRING_AGG(DISTINCT r.reason_desc, ', ') AS return_reasons
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerWithDemographics AS (
    SELECT 
        cus.c_customer_id,
        cus.c_first_name,
        cus.c_last_name,
        cus.total_returns,
        cus.total_return_quantity,
        cus.total_returned_amount,
        cus.total_returned_tax,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_education_status
    FROM 
        CustomerReturnSummary cus
    LEFT JOIN 
        customer_demographics dem ON cus.c_customer_id = dem.cd_demo_sk
),
RankedCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_returned_amount DESC) AS rank
    FROM 
        CustomerWithDemographics
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.total_returns,
    c.total_return_quantity,
    c.total_returned_amount,
    c.total_returned_tax,
    c.return_reasons,
    CASE 
        WHEN c.rank <= 10 THEN 'Top Returner'
        ELSE 'Regular Returner'
    END AS returner_category
FROM 
    RankedCustomers c
WHERE 
    c.total_returns > 0
ORDER BY 
    c.cd_gender, c.total_returned_amount DESC;
