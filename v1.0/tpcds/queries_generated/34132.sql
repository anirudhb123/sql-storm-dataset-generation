
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id

    UNION ALL

    SELECT 
        cs.c_customer_sk, 
        cs.c_customer_id, 
        cs.total_spent + COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent
    FROM 
        CustomerSales cs
    LEFT JOIN 
        store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs.c_customer_sk, cs.c_customer_id, cs.total_spent
), 

TopCustomers AS (
    SELECT 
        c.customer_id, 
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerSales c
)

SELECT 
    tc.customer_id, 
    tc.total_spent,
    COALESCE(sm.sm_carrier, 'No carrier') AS shipping_carrier
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
