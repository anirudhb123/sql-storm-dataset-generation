
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
), 
HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.order_count,
        cs.last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        CustomerSales AS cs
    JOIN 
        customer_demographics AS cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerSales
        )
)
SELECT 
    h.c_customer_id,
    h.total_spent,
    h.order_count,
    h.last_purchase_date,
    h.cd_gender,
    h.cd_marital_status
FROM 
    HighSpenders AS h
ORDER BY 
    h.total_spent DESC
LIMIT 10;
