
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_spent,
        cp.order_count,
        DENSE_RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchases cp
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.order_count, 0) AS order_count,
    IFNULL(tc.rank, 'Not Ranked') AS customer_rank,
    (SELECT 
        COUNT(DISTINCT ws2.ws_order_number) 
     FROM 
        web_sales ws2 
     WHERE 
        ws2.ws_ship_customer_sk = tc.c_customer_sk 
        AND ws2.ws_net_paid > 200
    ) AS high_value_order_count
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    tc.total_spent DESC;
