
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM CustomerSales cs
    WHERE cs.total_spent IS NOT NULL
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
StorePerformance AS (
    SELECT 
        ts.s_store_sk,
        ts.s_store_name,
        ts.total_sales,
        DENSE_RANK() OVER (ORDER BY ts.total_sales DESC) AS store_rank
    FROM TopStores ts
)
SELECT 
    ts.s_store_name,
    ts.total_sales,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent AS customer_spending,
    COALESCE(cs.order_count, 0) AS total_orders,
    CASE
        WHEN cs.total_spent >= 1000 THEN 'High Value Customer'
        WHEN cs.total_spent >= 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM StorePerformance ts
LEFT JOIN TopSpenders cs ON ts.total_sales > 0
WHERE ts.store_rank <= 10
ORDER BY ts.total_sales DESC, cs.total_spent DESC;
