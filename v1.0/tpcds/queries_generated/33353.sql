
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand_id,
           CAST(i_item_desc AS VARCHAR(200)) AS item_path
    FROM item
    WHERE i_current_price > 20.00
    
    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_brand_id,
           CONCAT(ih.item_path, ' -> ', i.i_item_desc) AS item_path
    FROM item_hierarchy ih
    JOIN item i ON i.i_brand_id = ih.i_brand_id
    WHERE i.i_current_price < 50.00 AND ih.i_item_sk <> i.i_item_sk
),

sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_item_sk
),

customer_overview AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)

SELECT 
    ih.item_path,
    cs.total_sales,
    co.total_net_profit,
    COALESCE(co.total_orders, 0) AS total_orders,
    CASE 
        WHEN co.profit_rank IS NOT NULL THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM item_hierarchy ih
JOIN sales_summary cs ON ih.i_item_sk = cs.ws_item_sk
FULL OUTER JOIN customer_overview co ON cs.total_sales > 1000 AND co.total_net_profit IS NOT NULL
WHERE ih.item_path LIKE '%electronics%'
ORDER BY ih.item_path, cs.total_sales DESC, co.total_net_profit DESC;
