
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_quantity) AS total_returned_quantity,
        SUM(sr.return_amt) AS total_returned_amt,
        AVG(sr.return_quantity) AS avg_returned_quantity,
        AVG(sr.return_amt) AS avg_returned_amt,
        cd.gender,
        cd.marital_status,
        cd.education_status
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.gender, cd.marital_status, cd.education_status
),
highest_returned_customers AS (
    SELECT 
        customer_id,
        total_returns,
        total_returned_quantity,
        total_returned_amt,
        avg_returned_quantity,
        avg_returned_amt,
        gender,
        marital_status,
        education_status,
        RANK() OVER (ORDER BY total_returned_amt DESC) AS rank
    FROM 
        customer_stats
)
SELECT 
    hrc.customer_id,
    hrc.total_returns,
    hrc.total_returned_quantity,
    hrc.total_returned_amt,
    hrc.avg_returned_quantity,
    hrc.avg_returned_amt,
    hrc.gender,
    hrc.marital_status,
    hrc.education_status
FROM 
    highest_returned_customers hrc
WHERE 
    hrc.rank <= 10
ORDER BY 
    hrc.total_returned_amt DESC;
