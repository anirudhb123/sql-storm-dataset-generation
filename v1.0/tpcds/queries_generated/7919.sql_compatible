
WITH HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TopItems AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
    ORDER BY 
        total_sold DESC
    LIMIT 10
),
StoresStats AS (
    SELECT 
        s.s_store_id, 
        s.s_store_name, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_store_sk
    GROUP BY 
        s.s_store_id, s.s_store_name
)
SELECT 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.cd_gender, 
    hvc.cd_marital_status, 
    ti.i_item_desc, 
    ss.s_store_name, 
    ss.total_orders, 
    ss.total_revenue
FROM 
    HighValueCustomers hvc
CROSS JOIN 
    TopItems ti
JOIN 
    StoresStats ss ON ss.total_revenue > 10000
WHERE 
    hvc.total_spent > 5000
ORDER BY 
    hvc.total_spent DESC, 
    ss.total_revenue DESC;
