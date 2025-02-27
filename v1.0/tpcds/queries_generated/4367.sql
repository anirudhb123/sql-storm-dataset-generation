
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name || ' ' || cs.c_last_name AS full_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent IS NOT NULL
), 
QualifiedCustomers AS (
    SELECT 
        ts.full_name,
        ts.total_spent,
        dt.d_date,
        ws.sm_ship_mode_id,
        ws.ws_order_number
    FROM 
        TopSpenders ts
    INNER JOIN 
        web_sales ws ON ts.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
    WHERE 
        ts.spend_rank <= 10
)
SELECT 
    qc.full_name,
    qc.total_spent,
    COUNT(DISTINCT qc.ws_order_number) AS unique_orders,
    SUM(CASE 
        WHEN qc.sm_ship_mode_id IS NULL THEN 0 
        ELSE 1 
    END) AS delivered_orders,
    AVG(DATE_PART('days', CURRENT_DATE - qc.d_date)) AS avg_days_since_last_order
FROM 
    QualifiedCustomers qc
GROUP BY 
    qc.full_name, qc.total_spent
ORDER BY 
    total_spent DESC;
