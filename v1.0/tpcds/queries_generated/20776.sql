
WITH RankedReturns AS (
    SELECT 
        sr.sk AS return_sk, 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.return_quantity, 
        sr.return_amount, 
        sr.return_tax, 
        sr.customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        COUNT(ws.order_number) AS order_count,
        SUM(ws.net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SpendingAnalysis AS (
    SELECT 
        cs.customer_sk, 
        cs.order_count, 
        cs.total_spent,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Sales'
            WHEN cs.total_spent < 100 THEN 'Low Spending'
            ELSE 'High Spending'
        END AS spending_category
    FROM 
        CustomerSales cs
)
SELECT 
    ca.city, 
    ca.state,
    COALESCE(rs.rn, 'No Returns') AS return_rank,
    sa.spending_category,
    SUM(sr.return_quantity) AS total_returned_quantity,
    SUM(sr.return_amount) AS total_returned_amount
FROM 
    RankedReturns rs
FULL OUTER JOIN 
    SpendingAnalysis sa ON rs.customer_sk = sa.customer_sk
LEFT JOIN 
    customer_address ca ON rs.customer_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns sr ON rs.return_sk = sr.returned_date_sk
GROUP BY 
    ca.city, 
    ca.state, 
    return_rank, 
    sa.spending_category
HAVING 
    SUM(sr.return_quantity) IS NULL OR SUM(sr.returned_amount) > 0
ORDER BY 
    ca.state, return_rank DESC;
