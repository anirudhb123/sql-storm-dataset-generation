
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.purchase_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.purchase_count,
    COALESCE(d.d_dow, 'N/A') AS last_purchase_day_of_week,
    CASE 
        WHEN hvc.purchase_count > 10 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS buyer_category
FROM 
    HighValueCustomers hvc
LEFT OUTER JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ss.ss_sold_date_sk)
                                 FROM store_sales ss 
                                 WHERE ss.ss_customer_sk = hvc.c_customer_sk)
ORDER BY 
    hvc.total_spent DESC;
