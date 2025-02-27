
WITH RECURSIVE Inventory_Analysis AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rank
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand IS NOT NULL
),
Sales_Summary AS (
    SELECT 
        w.warehouse_id,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales,
        AVG(COALESCE(ws_net_profit, 0)) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.warehouse_id
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(ws.net_paid, 0)) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
Filtered_Customers AS (
    SELECT 
        * 
    FROM 
        Customer_Demographics 
    WHERE 
        total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                Customer_Demographics
        )
)
SELECT 
    i.inv_warehouse_sk,
    i.inv_item_sk,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    ss.total_sales,
    ss.avg_net_profit,
    f.customer_count
FROM 
    Inventory_Analysis i
JOIN 
    Sales_Summary ss ON i.inv_warehouse_sk = ss.warehouse_id
LEFT JOIN 
    Filtered_Customers f ON f.cd_demo_sk = i.inv_item_sk
WHERE 
    i.rank = 1
GROUP BY 
    i.inv_warehouse_sk, 
    i.inv_item_sk, 
    ss.total_sales, 
    ss.avg_net_profit, 
    f.customer_count
HAVING 
    SUM(i.inv_quantity_on_hand) > 1000
ORDER BY 
    total_quantity_on_hand DESC, ss.total_sales DESC;
