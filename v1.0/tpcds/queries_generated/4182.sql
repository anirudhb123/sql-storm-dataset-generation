
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws.ws_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
return_summary AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_value
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
final_report AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_revenue,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        iv.total_inventory,
        (ss.total_revenue - COALESCE(rs.total_return_value, 0)) AS net_revenue,
        CASE 
            WHEN iv.total_inventory > 0 THEN (ss.total_quantity::decimal / iv.total_inventory) * 100 
            ELSE 0 
        END AS sales_to_inventory_ratio
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        return_summary rs ON i.i_item_sk = rs.cr_item_sk
    LEFT JOIN 
        inventory_data iv ON i.i_item_sk = iv.inv_item_sk
)
SELECT 
    f.i_item_id, 
    f.i_item_desc,
    f.total_quantity,
    f.total_revenue,
    f.total_returns,
    f.total_return_value,
    f.total_inventory,
    f.net_revenue,
    f.sales_to_inventory_ratio
FROM 
    final_report f
WHERE 
    f.net_revenue > 1000
ORDER BY 
    f.sales_to_inventory_ratio DESC
LIMIT 50;
