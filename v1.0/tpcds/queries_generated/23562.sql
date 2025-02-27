
WITH RankedReturns AS (
    SELECT 
        wr.returning_customer_sk,
        wr.wr_returned_date_sk,
        wr_return_quantity,
        wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr_returned_date_sk) AS return_rank
    FROM 
        web_returns wr
    WHERE 
        wr_returned_date_sk IS NOT NULL 
        AND wr_return_quantity > 0
),
CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk
),
EligibleCustomers AS (
    SELECT 
        cs.c_customer_sk
    FROM 
        CustomerSpend cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating = 'Good'
        AND cs.total_spent > (
            SELECT AVG(total_spent) FROM CustomerSpend WHERE total_spent IS NOT NULL
        )
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ec.c_customer_sk) AS eligible_customer_count,
    AVG(rr.wr_return_amt) AS avg_return_amount
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    RankedReturns rr ON rr.returning_customer_sk = c.c_customer_sk
JOIN 
    EligibleCustomers ec ON ec.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_country = 'USA'
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ec.c_customer_sk) > 5
ORDER BY 
    avg_return_amount DESC;
