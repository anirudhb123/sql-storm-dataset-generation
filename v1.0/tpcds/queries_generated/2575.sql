
WITH SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sum(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY sum(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_net_profit DESC) AS state_rank
    FROM 
        SalesData s
    LEFT JOIN 
        customer_address ca ON s.c_customer_sk = ca.ca_address_sk
    WHERE 
        s.order_count > 5
)
SELECT 
    DISTINCT tc.c_first_name,
    tc.c_last_name,
    coalesce(tc.ca_city, 'N/A') AS city,
    coalesce(tc.ca_state, 'N/A') AS state,
    tc.total_net_profit
FROM 
    TopCustomers tc
WHERE 
    tc.state_rank <= 5
ORDER BY 
    tc.total_net_profit DESC, 
    tc.c_last_name ASC;
