
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerPurchases
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.web_order_count,
    tc.catalog_order_count,
    tc.store_order_count,
    d.d_date,
    d.d_month_seq,
    d.d_year,
    CASE 
        WHEN d.d_holiday = 'Y' THEN 'Holiday'
        ELSE 'Regular Day'
    END AS day_type
FROM 
    TopCustomers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) 
                                  FROM web_sales ws 
                                  WHERE ws.ws_bill_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rank <= 10
ORDER BY 
    total_spent DESC;
