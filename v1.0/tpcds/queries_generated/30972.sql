
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.bill_customer_sk
    HAVING 
        SUM(ws.net_profit) > 500
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        sd.total_net_profit
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.bill_customer_sk = c.c_customer_sk
    WHERE 
        sd.rn <= 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(a.ca_city, 'Unknown') AS customer_city,
    COALESCE(a.ca_state, 'Unknown') AS customer_state,
    t.d_year,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_net_paid) AS avg_net_paid
FROM 
    TopCustomers tc
LEFT JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
LEFT JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
WHERE 
    t.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, t.d_year
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    avg_net_paid DESC
LIMIT 15;
