
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        LISTAGG(DISTINCT sm.sm_carrier, ', ') WITHIN GROUP (ORDER BY sm.sm_carrier) AS ship_carriers
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451520 AND 2452140 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        cs.ship_carriers,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    tc.ship_carriers
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10 
ORDER BY 
    tc.total_spent DESC;
