
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT *,
        RANK() OVER (ORDER BY total_spent DESC) as rank
    FROM CustomerSales
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.web_orders,
    tc.catalog_orders,
    tc.store_orders
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
    AND EXISTS (
        SELECT 1
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > (
            SELECT AVG(cd2.cd_purchase_estimate)
            FROM customer_demographics cd2
        )
    )
ORDER BY 
    tc.total_spent DESC;
