
WITH RECURSIVE high_value_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_date,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, c_birth_date
    HAVING 
        SUM(ws_net_paid) > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_date,
        SUM(ws.ws_net_paid)
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        high_value_customers hvc ON c.c_customer_sk <> hvc.c_customer_sk
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_date
)
SELECT 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.total_spent,
    CASE 
        WHEN hvc.total_spent > 5000 THEN 'Gold' 
        WHEN hvc.total_spent > 1000 THEN 'Silver' 
        ELSE 'Bronze' 
    END AS customer_tier,
    COALESCE(i.i_brand, 'Unknown') AS preferred_brand
FROM 
    high_value_customers hvc
LEFT JOIN 
    item i ON i.i_item_sk = (
        SELECT 
            ws.ws_item_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk = hvc.c_customer_sk 
        ORDER BY 
            ws.ws_sold_date_sk DESC 
        LIMIT 1
    )
WHERE 
    hvc.total_spent > (
        SELECT AVG(total_spent) FROM high_value_customers
    )
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
