
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count
),
SelectedCustomers AS (
    SELECT 
        r.c_customer_sk, 
        r.cd_gender, 
        r.total_orders, 
        r.total_spent
    FROM 
        RecursiveCTE r
    WHERE 
        r.total_orders > (
            SELECT 
                AVG(total_orders) 
            FROM 
                RecursiveCTE
        )
    AND r.gender_rank <= 3
),
TopCustomers AS (
    SELECT 
        sc.c_customer_sk, 
        sc.cd_gender, 
        sc.total_orders, 
        sc.total_spent,
        RANK() OVER (ORDER BY sc.total_spent DESC) AS spending_rank
    FROM 
        SelectedCustomers sc
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    cc.cc_name AS call_center_name,
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_net_paid_inc_tax
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    call_center cc ON c.c_current_addr_sk = cc.cc_call_center_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (c.c_birth_month IS NOT NULL OR c.c_birth_day IS NOT NULL)
    AND (ws.ws_net_paid_inc_tax IS NOT NULL OR ws.ws_net_paid IS NULL)
    AND EXISTS (
        SELECT 1 
        FROM catalog_sales cs 
        WHERE cs.cs_bill_customer_sk = c.c_customer_sk
        GROUP BY cs.cs_bill_customer_sk
        HAVING SUM(cs.cs_ext_sales_price) > 100
    )
ORDER BY 
    tc.spending_rank, c.c_last_name DESC
LIMIT 10;
