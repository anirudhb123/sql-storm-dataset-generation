
WITH CTE_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws_item_sk
),
CTE_Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_gender IS NOT NULL OR cd_gender != 'X'
    GROUP BY cd_demo_sk, cd_gender
),
CTE_Inventory AS (
    SELECT 
        inv_item_sk,
        inv_quantity_on_hand,
        LEAD(inv_quantity_on_hand) OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk) AS next_quantity,
        LAG(inv_quantity_on_hand) OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk) AS previous_quantity
    FROM inventory
    WHERE inv_quantity_on_hand IS NOT NULL
),
CTE_Store AS (
    SELECT 
        s_store_id,
        SUM(ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales 
    FROM store_sales
    JOIN store ON ss_store_sk = s_store_sk
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY s_store_id
)
SELECT 
    s_store_id,
    inventory_stats.inv_item_sk,
    inventory_stats.inv_quantity_on_hand,
    sales.total_quantity,
    sales.total_profit,
    CASE
        WHEN sales.total_profit IS NULL THEN 'Profit data not available'
        WHEN sales.total_profit < 0 THEN 'Loss incurred'
        ELSE 'Profit achieved'
    END AS profit_status,
    customer_demo.cd_gender,
    customer_demo.customer_count,
    ARRAY_AGG(DISTINCT CONCAT_WS(' ', w_name, 'from', w_city, w_state)) AS warehouse_info
FROM CTE_Sales sales
JOIN CTE_Inventory inventory_stats ON sales.ws_item_sk = inventory_stats.inv_item_sk
JOIN CTE_Store store_data ON store_data.store_profit > 1000
JOIN CTE_Customer_Demographics customer_demo ON sales.ws_item_sk IN (SELECT DISTINCT i_item_sk FROM item WHERE i_category LIKE '%Electronics%')
LEFT JOIN warehouse AS w ON w.w_warehouse_sk = (SELECT MAX(w_warehouse_sk) FROM warehouse WHERE w_state = 'CA')
WHERE inventory_stats.next_quantity IS NOT NULL
    AND (customer_demo.customer_count > 100 OR customer_demo.cd_gender IS NULL)
GROUP BY s_store_id, inventory_stats.inv_item_sk, inventory_stats.inv_quantity_on_hand, sales.total_quantity, sales.total_profit, customer_demo.cd_gender, customer_demo.customer_count
HAVING MAX(inventory_stats.inv_quantity_on_hand) > COALESCE(NULLIF(AVG(inventory_stats.inv_quantity_on_hand), 0), 1)
ORDER BY store_data.store_profit DESC, sales.total_profit DESC;
