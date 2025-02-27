
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    h.order_count,
    r.r_reason_desc AS return_reason,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
FROM 
    HighSpenders h
LEFT JOIN 
    store_returns sr ON h.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY 
    h.c_first_name, h.c_last_name, h.total_spent, h.order_count, r.r_reason_desc
ORDER BY 
    h.total_spent DESC, h.order_count DESC
LIMIT 10
UNION ALL
SELECT 
    'Aggregate' AS c_first_name,
    NULL AS c_last_name,
    AVG(total_spent) AS total_spent,
    SUM(order_count) AS total_orders,
    NULL AS return_reason,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
FROM 
    HighSpenders h
LEFT JOIN 
    store_returns sr ON h.c_customer_sk = sr.sr_customer_sk;
