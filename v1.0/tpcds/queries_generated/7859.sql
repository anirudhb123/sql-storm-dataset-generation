
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        DATEDIFF(CURRENT_DATE, c.c_first_sales_date_sk) <= 365
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cp.total_spent,
        cp.purchase_count,
        cp.gender_rank
    FROM 
        CustomerPurchase cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.gender_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.purchase_count,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
ORDER BY 
    total_spent DESC;
