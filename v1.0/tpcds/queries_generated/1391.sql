
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_paid DESC) AS rank_order
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spender_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
SalesReturnDetails AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returned_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent,
    COALESCE(srd.total_returned_amt, 0) AS total_returned_amt,
    hs.spender_rank
FROM 
    customer c
JOIN 
    CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    SalesReturnDetails srd ON c.c_customer_sk = srd.sr_customer_sk
JOIN 
    HighSpenders hs ON cs.c_customer_sk = hs.c_customer_sk
WHERE 
    (cs.total_orders > 5 OR hs.spender_rank <= 10)
ORDER BY 
    cs.total_spent DESC, cs.total_orders DESC
FETCH FIRST 100 ROWS ONLY;
