
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_ship_tax) DESC) AS rank
    FROM 
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        CASE 
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Other'
        END AS marital_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE
        cs.total_spent > (
            SELECT AVG(total_spent) FROM CustomerSales
        )
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.marital_status,
    COALESCE(SUM(ss.ss_quantity), 0) AS total_items_purchased,
    COALESCE(AVG(ss.ss_sales_price), 0.00) AS avg_sales_price
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    store_sales ss ON hvc.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    hvc.c_first_name, hvc.c_last_name, hvc.total_spent, hvc.marital_status
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
