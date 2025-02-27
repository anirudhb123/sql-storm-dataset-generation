
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) as rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status
    FROM RankedCustomers rc
    JOIN customer c ON rc.c_customer_id = c.c_customer_id
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE rc.rank <= 5
),
FrequentReturnCustomers AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
    HAVING COUNT(sr.sr_ticket_number) > 3
)
SELECT 
    tc.full_name,
    tc.gender,
    tc.marital_status,
    tc.education_status,
    frc.return_count,
    frc.total_return
FROM TopCustomers tc
LEFT JOIN FrequentReturnCustomers frc ON tc.customer_id = frc.sr_customer_sk
WHERE frc.return_count IS NOT NULL
ORDER BY frc.total_return DESC
LIMIT 10;
