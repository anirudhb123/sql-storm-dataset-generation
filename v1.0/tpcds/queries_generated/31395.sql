
WITH RECURSIVE CustomerReturnCTE AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        1 AS Level,
        sr_customer_sk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    UNION ALL
    SELECT 
        sr.returned_date_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        cte.Level + 1,
        sr.customer_sk
    FROM 
        store_returns sr
    INNER JOIN 
        CustomerReturnCTE cte ON sr.customer_sk = cte.sr_customer_sk AND sr.return_quantity > cte.sr_return_quantity
    WHERE 
        cte.Level < 3
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT cr.returning_customer_sk) AS ReturnCount,
        SUM(cr.return_amt) AS TotalReturnAmount
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturnCTE cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopReturns AS (
    SELECT 
        cus.c_customer_id,
        cus.ReturnCount,
        cus.TotalReturnAmount,
        RANK() OVER (ORDER BY cus.TotalReturnAmount DESC) AS rn
    FROM 
        CustomerSummary cus
    WHERE 
        cus.TotalReturnAmount IS NOT NULL
)
SELECT 
    c.c_customer_id,
    COALESCE(cus.ReturnCount, 0) AS TotalReturns,
    COALESCE(cus.TotalReturnAmount, 0.00) AS TotalReturnAmount,
    d.d_date AS ReturnDate
FROM 
    customer c
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN 
    TopReturns cus ON cus.c_customer_id = c.c_customer_id
WHERE 
    (c.c_birth_month = 12 OR c.c_birth_month = 1)
    AND (c.c_preferred_cust_flag IS NOT NULL OR c.c_email_address IS NOT NULL)
    AND sr.sr_return_quantity IS NOT NULL
ORDER BY 
    TotalReturnAmount DESC;
