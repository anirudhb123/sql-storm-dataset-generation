
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        customer_name,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM 
        CustomerSales
)
SELECT 
    tc.customer_name,
    tc.total_profit,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rank <= 10 
ORDER BY 
    tc.total_profit DESC;
