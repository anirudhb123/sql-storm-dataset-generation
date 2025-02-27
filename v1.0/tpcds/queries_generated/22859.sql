
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
HighSpenders AS (
    SELECT 
        rc.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        RankedCustomers rc
    JOIN 
        web_sales ws ON rc.c_customer_id = ws.ws_bill_customer_sk
    WHERE 
        rc.rn <= 5
    GROUP BY 
        rc.c_customer_id
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_amt), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
FinalSummary AS (
    SELECT 
        hs.c_customer_id, 
        hs.total_spent, 
        cr.total_returns, 
        cr.return_count,
        CASE 
            WHEN cr.return_count > 0 THEN (cr.total_returns / hs.total_spent) * 100
            ELSE NULL 
        END AS return_rate
    FROM 
        HighSpenders hs
    LEFT JOIN 
        CustomerReturns cr ON hs.c_customer_id = cr.c_customer_id
)
SELECT 
    f.c_customer_id, 
    f.total_spent, 
    f.total_returns, 
    f.return_rate,
    CASE 
        WHEN f.return_rate IS NULL THEN 'NO RETURNS'
        WHEN f.return_rate < 10 THEN 'LOW RETURN RATE'
        WHEN f.return_rate BETWEEN 10 AND 20 THEN 'MEDIUM RETURN RATE'
        ELSE 'HIGH RETURN RATE'
    END AS return_category
FROM 
    FinalSummary f
WHERE 
    f.total_returns < 100 
    AND f.return_rate IS NOT NULL 
ORDER BY 
    f.total_spent DESC
LIMIT 10;
