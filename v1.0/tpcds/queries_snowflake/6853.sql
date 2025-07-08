
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        total_net_profit, 
        order_count,
        RANK() OVER (ORDER BY total_net_profit DESC) AS customer_rank
    FROM 
        CustomerSales
),
SalesInfo AS (
    SELECT 
        t.c_customer_id AS customer_id,
        t.total_net_profit,
        t.order_count,
        d.d_month_seq,
        d.d_year,
        d.d_quarter_seq,
        sm.sm_type
    FROM 
        TopCustomers t 
    JOIN 
        date_dim d ON d.d_year = 2023
    JOIN 
        ship_mode sm ON sm.sm_ship_mode_sk = (
            SELECT ws.ws_ship_mode_sk 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk IN (
                SELECT c.c_customer_sk 
                FROM customer c 
                WHERE c.c_customer_id = t.c_customer_id
            ) 
            LIMIT 1
        )
    WHERE 
        t.customer_rank <= 10
)
SELECT 
    si.customer_id, 
    si.total_net_profit, 
    si.order_count, 
    si.d_month_seq, 
    si.d_year, 
    si.d_quarter_seq, 
    si.sm_type
FROM 
    SalesInfo si
ORDER BY 
    si.total_net_profit DESC;
