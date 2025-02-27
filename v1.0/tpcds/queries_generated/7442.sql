
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        cp.total_spent,
        cp.total_orders,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.total_orders,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.rank <= 10
    AND cd.cd_gender = 'F'
ORDER BY 
    tc.total_spent DESC;
