
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer AS c
        LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_spent,
        cs.gender_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.gender_rank <= 10
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_orders,
    t.total_spent,
    t.avg_spent,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ': ', SUM(ws.ws_quantity)) ORDER BY SUM(ws.ws_quantity) DESC) AS purchased_items
FROM 
    TopCustomers t
    LEFT JOIN web_sales ws ON t.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    t.c_customer_sk, t.c_first_name, t.c_last_name, t.total_orders, t.total_spent, t.avg_spent
ORDER BY 
    t.total_spent DESC
LIMIT 20;
