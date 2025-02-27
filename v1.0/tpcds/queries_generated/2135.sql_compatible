
WITH CustomerReturns AS (
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amount,
        SUM(sr.return_quantity) AS total_return_quantity
    FROM 
        customer cu
    LEFT JOIN 
        store_returns sr ON cu.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        cu.c_customer_sk, cu.c_first_name, cu.c_last_name
),
TopRefunds AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amount DESC) AS rn
    FROM 
        CustomerReturns cr
)
SELECT 
    t.rn,
    t.c_first_name,
    t.c_last_name,
    COALESCE(t.total_returns, 0) AS return_count,
    COALESCE(t.total_return_amount, 0) AS return_amount
FROM 
    TopRefunds t
WHERE 
    t.rn <= 10
UNION ALL
SELECT 
    NULL AS rn,
    'Overall Total' AS c_first_name,
    NULL AS c_last_name,
    COUNT(*) AS return_count,
    SUM(COALESCE(total_return_amount, 0)) AS return_amount
FROM 
    CustomerReturns
WHERE 
    total_returns IS NOT NULL
ORDER BY 
    rn;
