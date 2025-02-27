
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY COUNT(ws_order_number) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_orders,
        total_revenue
    FROM 
        RankedSales
    WHERE 
        order_rank <= 10
),
StoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    sc.s_store_id,
    sc.s_store_name,
    COALESCE(ss.total_store_profit, 0) AS total_profit,
    tc.total_orders,
    tc.total_revenue,
    'Top Customer' AS customer_status
FROM 
    store sc
LEFT JOIN 
    StoreSales ss ON sc.s_store_sk = ss.ss_store_sk
FULL OUTER JOIN 
    TopCustomers tc ON ss.ss_store_sk = tc.total_orders
WHERE 
    COALESCE(ss.total_store_profit, 0) > 10000
    OR tc.total_orders IS NOT NULL
ORDER BY 
    total_profit DESC, 
    total_revenue DESC;
