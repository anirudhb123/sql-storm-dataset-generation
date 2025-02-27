
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_customer_sk,
        COUNT(ws_item_sk) AS total_items,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid_inc_tax) AS total_paid,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_customer_sk
    
    UNION ALL
    
    SELECT 
        sh.ws_customer_sk,
        sh.total_items + ws.total_items,
        sh.total_profit + ws.total_profit,
        sh.total_paid + ws.total_paid,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN web_sales ws ON sh.ws_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sh.total_items,
    sh.total_profit,
    sh.total_paid,
    RANK() OVER (ORDER BY sh.total_profit DESC) AS profit_rank,
    CASE 
        WHEN sh.total_paid IS NULL THEN 'No Sales'
        WHEN sh.total_paid < 10000 THEN 'Low Spender'
        WHEN sh.total_paid BETWEEN 10000 AND 50000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS customer_segments
FROM 
    sales_hierarchy sh
JOIN 
    customer c ON sh.ws_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND
    (cd.cd_marital_status IS NOT NULL OR cd.cd_education_status IS NOT NULL)
ORDER BY 
    sh.total_profit DESC
LIMIT 10;

WITH item_inventory AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ws.ws_order_number,
    ws.ws_ship_date_sk,
    wp.wp_url,
    ii.total_inventory,
    CASE 
        WHEN ws.ws_net_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Recorded'
    END AS profit_status
FROM 
    web_sales ws
JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    item_inventory ii ON ws.ws_item_sk = ii.i_item_id
WHERE 
    ws.ws_sold_date_sk = (
        SELECT MAX(ws2.ws_sold_date_sk) 
        FROM web_sales ws2 
        WHERE ws2.ws_customer_sk = ws.ws_customer_sk
    );
