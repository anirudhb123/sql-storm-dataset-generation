
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_spent, 
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk, 
        w.w_warehouse_name,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ws.total_items,
    ws.total_quantity
FROM 
    TopCustomers tc
LEFT JOIN 
    WarehouseStats ws ON tc.rank <= 10
WHERE 
    ws.total_quantity IS NOT NULL
ORDER BY 
    tc.total_spent DESC, 
    tc.c_last_name ASC
LIMIT 5 
UNION ALL
SELECT 
    'Other' AS c_first_name,
    'Customers' AS c_last_name,
    SUM(total_spent) AS total_spent,
    SUM(total_items) AS total_items,
    SUM(total_quantity) AS total_quantity
FROM 
    (SELECT 
        SUM(ws.net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_items,
        0 AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk NOT IN (SELECT c_customer_sk FROM TopCustomers)
    ) AS subquery
GROUP BY 
    total_spent;
