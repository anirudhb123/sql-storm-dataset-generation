
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1995
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cp.total_net_profit,
        cp.total_orders,
        DENSE_RANK() OVER (ORDER BY cp.total_net_profit DESC) AS rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.total_orders,
    c.ca_city,
    c.ca_state,
    (SELECT COUNT(DISTINCT ws.ws_web_page_sk)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS unique_web_pages_visited
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
