
WITH TotalReturns AS (
    SELECT 
        sr_returned_date_sk, 
        COUNT(sr_ticket_number) AS return_count, 
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_returned_date_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
ReturnDetails AS (
    SELECT 
        d.d_date,
        tr.return_count,
        tr.total_return_amount,
        COALESCE(HC.total_orders, 0) AS high_value_order_count,
        COALESCE(HC.total_spent, 0) AS high_value_total_spent
    FROM 
        date_dim d
    LEFT JOIN 
        TotalReturns tr ON d.d_date_sk = tr.sr_returned_date_sk
    LEFT JOIN 
        HighValueCustomers HC ON d.d_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales ws WHERE ws.ship_customer_sk = HC.c_customer_sk)
    WHERE 
        d.d_year = 2023
)
SELECT 
    dd.d_date,
    dd.return_count,
    dd.total_return_amount,
    dd.high_value_order_count,
    dd.high_value_total_spent,
    CONCAT('Total Returns on ', TO_CHAR(dd.d_date, 'FMMonth DD, YYYY'), ': ', COALESCE(dd.return_count, 0)) AS return_summary
FROM 
    ReturnDetails dd
ORDER BY 
    dd.d_date;
