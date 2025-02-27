
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    tc.total_orders,
    tc.total_spent
FROM 
    TopCustomers tc
JOIN 
    customer cu ON tc.c_customer_sk = cu.c_customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;

WITH ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        is.ws_item_sk,
        is.total_quantity_sold,
        is.total_profit,
        DENSE_RANK() OVER (ORDER BY is.total_profit DESC) AS rank
    FROM 
        ItemSales is
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity_sold,
    ti.total_profit
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_profit DESC;

SELECT 
    w.w_warehouse_id,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    warehouse w
JOIN 
    web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
GROUP BY 
    w.w_warehouse_id
ORDER BY 
    total_profit DESC
LIMIT 5;
