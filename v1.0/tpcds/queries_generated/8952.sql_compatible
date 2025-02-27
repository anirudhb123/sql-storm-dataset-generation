
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_credit_rating ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_credit_rating,
        rc.total_spent
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_order_value
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_id, tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.cd_marital_status, tc.cd_credit_rating, tc.total_spent
ORDER BY 
    total_spent DESC;
