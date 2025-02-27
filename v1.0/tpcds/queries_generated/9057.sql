
WITH CustomerWebSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452081 AND 2452100  -- arbitrary date range for testing
    GROUP BY 
        c.c_customer_id
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_id,
        cw.total_spent,
        cw.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerWebSales cw
        JOIN customer_demographics cd ON cw.c_customer_id = cd.cd_demo_sk
    WHERE 
        cw.total_spent > (SELECT AVG(total_spent) FROM CustomerWebSales)  -- Above average spenders
),
TopHighSpenders AS (
    SELECT 
        hsc.c_customer_id,
        ROW_NUMBER() OVER (ORDER BY hsc.total_spent DESC) AS rank
    FROM 
        HighSpendingCustomers hsc
)
SELECT 
    ths.c_customer_id,
    ths.rank,
    hsc.total_spent,
    hsc.total_orders,
    hsc.cd_gender,
    hsc.cd_marital_status,
    hsc.cd_education_status
FROM 
    TopHighSpenders ths
    JOIN HighSpendingCustomers hsc ON ths.c_customer_id = hsc.c_customer_id
WHERE 
    ths.rank <= 10  -- Top 10 high spending customers
ORDER BY 
    ths.rank;
