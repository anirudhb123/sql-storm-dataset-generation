
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(s.ws_net_profit) AS total_net_profit,
        COUNT(s.ws_order_number) AS total_orders,
        MAX(s.ws_sold_date_sk) AS last_order_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
High_Spending_Customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_net_profit,
        cs.total_orders,
        cs.last_order_date
    FROM 
        Customer_Sales cs
    WHERE 
        cs.total_net_profit > (
            SELECT AVG(total_net_profit) 
            FROM Customer_Sales
        )
),
Inventory_Analysis AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MAX(inv.inv_date_sk) AS last_inventory_date
    FROM 
        inventory inv 
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    cus.c_customer_id,
    cus.total_net_profit,
    inv.total_quantity,
    inv.last_inventory_date
FROM 
    High_Spending_Customers cus
LEFT JOIN 
    Inventory_Analysis inv ON cus.total_net_profit > 5000 
WHERE 
    inv.total_quantity IS NOT NULL 
ORDER BY 
    cus.total_net_profit DESC,
    inv.total_quantity ASC;
