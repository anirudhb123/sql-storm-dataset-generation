
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT sr.ticket_number) AS total_returns
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.first_name,
        c.last_name,
        cs.total_spent,
        cs.total_orders,
        cs.total_returns,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.rank,
    tc.c_customer_id,
    tc.first_name,
    tc.last_name,
    tc.total_spent,
    tc.total_orders,
    tc.total_returns,
    CASE 
        WHEN tc.total_returns > 0 THEN 'High Return Customer' 
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.rank;
