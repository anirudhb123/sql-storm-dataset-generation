
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        MAX(sd.d_date) AS last_purchase_date
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.gender,
        c.marital_status,
        c.total_spent,
        c.purchase_count,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) as ranking
    FROM 
        CustomerStats c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    h.customer_id,
    h.first_name,
    h.last_name,
    h.gender,
    h.marital_status,
    h.total_spent,
    h.purchase_count
FROM 
    HighSpenders h
WHERE 
    h.ranking <= 10
ORDER BY 
    h.total_spent DESC;
