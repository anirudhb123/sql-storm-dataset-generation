
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.total_orders
    FROM 
        sales_summary s
    JOIN 
        customer c ON s.c_customer_sk = c.c_customer_sk
    WHERE 
        s.rank <= 10
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    top_customers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender IS NOT NULL AND cd.cd_marital_status = 'M')
    OR (cd.cd_gender IS NULL AND tc.total_orders > 5)
ORDER BY 
    tc.total_sales DESC;

SELECT 
    inv.inv_warehouse_sk,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM 
    inventory inv
LEFT JOIN 
    web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
WHERE 
    inv.inv_date_sk = (SELECT MAX(inv2.inv_date_sk) FROM inventory inv2)
GROUP BY 
    inv.inv_warehouse_sk
HAVING 
    SUM(inv.inv_quantity_on_hand) > 0
UNION ALL
SELECT 
    inv.inv_warehouse_sk,
    NULL AS total_quantity,
    NULL AS avg_net_profit
FROM 
    store_sales ss
RIGHT JOIN 
    inventory inv ON ss.ss_item_sk = inv.inv_item_sk
WHERE 
    ss.ss_sold_date_sk IS NULL
ORDER BY 
    inv.inv_warehouse_sk;
