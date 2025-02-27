
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_returned_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopReturners AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.return_count,
        cr.total_returned_amount,
        cr.avg_return_quantity,
        RANK() OVER (ORDER BY cr.total_returned_amount DESC) AS return_rank
    FROM 
        CustomerReturnStats cr
    JOIN 
        customer c ON cr.c_customer_sk = c.c_customer_sk
)
SELECT 
    t.return_rank,
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.return_count,
    t.total_returned_amount,
    t.avg_return_quantity,
    d.d_year,
    d.d_month,
    d.d_weekday,
    w.w_warehouse_name,
    sou.store_name,
    sm.sm_carrier
FROM 
    TopReturners t
JOIN 
    web_sales ws ON t.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    store sou ON ws.ws_store_sk = sou.s_store_sk
JOIN 
    warehouse w ON sou.s_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    t.return_rank <= 100
ORDER BY 
    t.total_returned_amount DESC;
