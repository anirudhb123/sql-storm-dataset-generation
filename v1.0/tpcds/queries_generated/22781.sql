
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_amt DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.ticket_number) AS returns_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(COALESCE(sr.sr_return_quantity, 0)) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
HighestReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_return_amt,
        cr.returns_count,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS return_rank
    FROM 
        CustomerStats cr
    WHERE 
        cr.total_return_amt IS NOT NULL
),
TopReturningCustomers AS (
    SELECT 
        hr.sr_customer_sk,
        hr.total_return_amt,
        hr.returns_count,
        CASE 
            WHEN hr.returns_count > 5 THEN 'Frequent Returner'
            ELSE 'Casual Returner'
        END AS returner_type
    FROM 
        HighestReturns hr
    WHERE 
        hr.return_rank <= 10
),
FinalResults AS (
    SELECT 
        t.rcustomer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        tr.returner_type,
        COALESCE(t.avg_return_quantity, 0) AS avg_return_quantity
    FROM 
        TopReturningCustomers tr
    JOIN 
        customer c ON tr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN 
        (SELECT 
            sr_customer_sk,
            AVG(sr_return_quantity) AS avg_return_quantity
         FROM 
            store_returns
         GROUP BY 
            sr_customer_sk) t ON tr.sr_customer_sk = t.sr_customer_sk
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.returner_type,
    COALESCE(fr.avg_return_quantity, 0) AS average_return_quantity,
    CASE 
        WHEN fr.returner_type = 'Frequent Returner' AND fr.avg_return_quantity > 2 THEN 'Optimize Offer'
        ELSE 'Standard Offer'
    END AS recommendation
FROM 
    FinalResults fr
ORDER BY 
    fr.returner_type DESC, fr.avg_return_quantity DESC;
