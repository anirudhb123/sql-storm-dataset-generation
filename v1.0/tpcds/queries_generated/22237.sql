
WITH RankedReturns AS (
    SELECT 
        dw.d_date AS return_date,
        wr_return_quantity,
        wr_return_amt,
        wr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_returned_date_sk DESC) AS rn
    FROM 
        web_returns
    JOIN 
        date_dim ON wr_returned_date_sk = d_date_sk
    WHERE 
        wr_return_quantity > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT wr_returning_customer_sk) AS return_count,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_net_loss) AS avg_net_loss
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns rr ON c.c_customer_sk = rr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
EligibleCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.return_count,
        cs.total_return_amt,
        cs.avg_net_loss
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        (cs.return_count > 5 AND cs.total_return_amt BETWEEN 50 AND 500)
        OR (cs.avg_net_loss IS NOT NULL AND cs.avg_net_loss < 10)
)
SELECT 
    ec.c_customer_sk,
    ec.c_first_name,
    ec.c_last_name,
    COALESCE(STRING_AGG(DISTINCT CONCAT(TO_CHAR(rr.return_date, 'YYYY-MM-DD'), ': ', rr.wr_return_quantity)) 
                 ORDER BY rr.return_date), 'No returns') AS return_details
FROM 
    EligibleCustomers ec
LEFT JOIN 
    RankedReturns rr ON ec.c_customer_sk = rr.wr_returning_customer_sk
WHERE 
    rc.rn <= 3
GROUP BY 
    ec.c_customer_sk, ec.c_first_name, ec.c_last_name
ORDER BY 
    ec.c_customer_sk DESC
FETCH FIRST 10 ROWS ONLY;
