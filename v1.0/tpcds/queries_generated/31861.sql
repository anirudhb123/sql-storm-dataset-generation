
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss_sold_date_sk, ss_item_sk
    
    UNION ALL
    
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) + c.total_net_profit AS total_net_profit,
        COUNT(ss.ticket_number) + c.total_sales AS total_sales
    FROM store_sales ss
    JOIN Sales_CTE c ON ss_ss_item_sk = c.ss_item_sk AND ss.ss_sold_date_sk = c.ss_sold_date_sk + 1
    GROUP BY ss.sold_date_sk, ss.item_sk
),

Inventory_CTE AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory inv 
    WHERE inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY inv.inv_item_sk
),

Returns_CTE AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_net_profit, 0) AS total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(iv.total_quantity, 0) AS inventory_stock,
    CASE 
        WHEN COALESCE(s.total_net_profit, 0) > 10000 THEN 'High Profit'
        WHEN COALESCE(s.total_net_profit, 0) <= 10000 AND COALESCE(s.total_net_profit, 0) > 0 THEN 'Low Profit'
        ELSE 'No Profit'
    END AS profit_category
FROM item i
LEFT JOIN Sales_CTE s ON i.i_item_sk = s.ss_item_sk
LEFT JOIN Returns_CTE r ON i.i_item_sk = r.sr_item_sk
LEFT JOIN Inventory_CTE iv ON i.i_item_sk = iv.inv_item_sk
WHERE i.i_current_price > 0
ORDER BY total_profit DESC, total_returns DESC;
