
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS total_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_net_profit,
        cp.total_orders,
        cp.total_items_purchased,
        DENSE_RANK() OVER (ORDER BY cp.total_net_profit DESC) AS rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.total_net_profit > 0
)
SELECT 
    tc.rank,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.total_items_purchased,
    d.d_month,
    d.d_year
FROM 
    TopCustomers tc
JOIN 
    date_dim d ON d.d_year = 2023
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.rank;
