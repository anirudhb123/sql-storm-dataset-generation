
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS total_orders,
        1 AS level
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
    
    UNION ALL
    
    SELECT 
        wh.inv_item_sk, 
        SUM(inventory.inv_quantity_on_hand) AS total_profit,
        COUNT(CASE WHEN wh.inv_date_sk IS NOT NULL THEN wh.inv_date_sk END) AS total_orders,
        sh.level + 1
    FROM 
        inventory wh
    JOIN 
        sales_hierarchy sh ON sh.cs_item_sk = wh.inv_item_sk
    GROUP BY 
        wh.inv_item_sk, sh.level
),
customer_performance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT *
    FROM customer_performance
    WHERE sales_rank <= 5
)
SELECT 
    th.c_first_name,
    th.c_last_name,
    COALESCE(sh.total_profit, 0) AS item_profit,
    th.total_sales,
    th.total_orders
FROM 
    top_customers th
LEFT JOIN 
    sales_hierarchy sh ON th.c_customer_sk = sh.cs_item_sk
WHERE 
    (th.total_sales > 1000 OR th.total_orders > 10)
ORDER BY 
    item_profit DESC, th.total_sales DESC;
