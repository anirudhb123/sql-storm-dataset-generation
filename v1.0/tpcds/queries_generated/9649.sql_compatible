
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.bill_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        * 
    FROM 
        SalesData 
    WHERE 
        rank_profit <= 10
),
SalesDetails AS (
    SELECT 
        tc.bill_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ws.item_sk,
        i.i_item_desc,
        ws.quantity,
        ws.net_profit
    FROM 
        TopCustomers tc
    JOIN 
        web_sales ws ON tc.bill_customer_sk = ws.bill_customer_sk
    JOIN 
        item i ON ws.item_sk = i.i_item_sk
)
SELECT 
    td.bill_customer_sk,
    td.c_first_name,
    td.c_last_name,
    SUM(td.net_profit) AS total_profit_from_top_items,
    COUNT(td.item_sk) AS total_items_sold,
    AVG(td.net_profit) AS average_profit_per_item,
    w.w_warehouse_name,
    w.w_city,
    w.w_state
FROM 
    SalesDetails td
JOIN 
    inventory inv ON td.item_sk = inv.inv_item_sk
JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    td.bill_customer_sk, td.c_first_name, td.c_last_name, w.w_warehouse_name, w.w_city, w.w_state
ORDER BY 
    total_profit_from_top_items DESC;
