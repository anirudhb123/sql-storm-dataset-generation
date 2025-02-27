
WITH Ranked_Sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS Sales_Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
Return_Summary AS (
    SELECT 
        sr_item_sk,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
Inventory_Status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NOT NULL THEN inv.inv_quantity_on_hand ELSE 0 END) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.total_orders, 0) AS order_count,
    COALESCE(cs.avg_order_value, 0) AS avg_order_value,
    i.total_inventory,
    rs.total_returned,
    rs.total_return_amount,
    CASE 
        WHEN rs.total_returned > 0 THEN 'High Return'
        WHEN i.total_inventory < 10 THEN 'Low Inventory'
        ELSE 'Normal'
    END AS Inventory_Status
FROM 
    customer c
LEFT JOIN 
    Customer_Stats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    Inventory_Status i ON i.inv_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    Return_Summary rs ON i.inv_item_sk = rs.sr_item_sk
WHERE 
    c.c_birth_year < 1980
    AND (COALESCE(i.total_inventory, 0) + COALESCE(rs.total_returned, 0)) > 5
ORDER BY 
    c.c_last_name,
    c.c_first_name;
