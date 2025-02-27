
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS ranking
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_orders > 0
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS store_profit
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_orders,
    tc.total_spent,
    COALESCE(hs.store_profit, 0) AS total_store_profit,
    CASE 
        WHEN tc.ranking <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    HighSpenders hs ON tc.c_customer_id = hs.c_customer_id
WHERE 
    tc.last_purchase_date > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
ORDER BY 
    tc.total_spent DESC;
