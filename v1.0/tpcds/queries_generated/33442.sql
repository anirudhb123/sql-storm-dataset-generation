
WITH RECURSIVE inventory_analysis AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_quantity_on_hand, 
        1 AS level
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand > 0

    UNION ALL

    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_quantity_on_hand - 10, 
        level + 1
    FROM 
        inventory_analysis
    WHERE 
        inv_quantity_on_hand - 10 > 0
),
customer_returns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_return_qty
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
web_returns_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_web_return_qty
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(c.total_return_qty, 0) AS total_catalog_returns,
        COALESCE(w.total_web_return_qty, 0) AS total_web_returns,
        COALESCE(s.total_sales_price, 0) AS total_sales_price,
        COALESCE(s.total_profit, 0) AS total_profit,
        (COALESCE(s.total_sales_price, 0) - COALESCE(c.total_return_qty, 0) * 10) AS net_performance
    FROM 
        item i
    LEFT JOIN 
        customer_returns c ON i.i_item_sk = c.cr_item_sk
    LEFT JOIN 
        web_returns_summary w ON i.i_item_sk = w.wr_item_sk
    LEFT JOIN 
        sales_summary s ON i.i_item_sk = s.ws_item_sk
)
SELECT 
    i.item_desc,
    MAX(CASE WHEN r.level IS NOT NULL THEN r.inv_quantity_on_hand ELSE 0 END) AS max_inventory,
    SUM(performance.net_performance) AS adjusted_performance
FROM 
    item_performance performance
LEFT JOIN 
    inventory_analysis r ON performance.i_item_sk = r.inv_item_sk
GROUP BY 
    i.item_desc
HAVING 
    adjusted_performance > 1000
ORDER BY 
    adjusted_performance DESC;
