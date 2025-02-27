
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk)
                                 FROM web_sales ws2 
                                 WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM ranked_sales rs
    WHERE rs.rank <= 5
    GROUP BY rs.ws_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(i.i_current_price, 0) AS current_price,
        COALESCE(i.i_wholesale_cost, 0) AS wholesale_cost,
        ii.eb_lower_bound,
        ii.eb_upper_bound
    FROM item i
    LEFT JOIN income_band ii ON (i.i_current_price BETWEEN ii.ib_lower_bound AND ii.ib_upper_bound)
),
sales_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ts.total_net_profit) AS sales_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM item_info i
    LEFT JOIN top_sales ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
),
final_output AS (
    SELECT 
        s.i_item_sk,
        s.i_product_name,
        s.sales_profit,
        s.total_orders,
        CASE 
            WHEN s.sales_profit > 0 THEN 'Profitable'
            WHEN s.sales_profit < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profit_status
    FROM sales_summary s
    WHERE s.sales_profit IS NOT NULL
)
SELECT 
    fo.i_item_sk,
    fo.i_product_name,
    fo.sales_profit,
    fo.total_orders,
    fo.profit_status,
    COALESCE(wa.w_warehouse_name, 'No Warehouse') AS warehouse_name
FROM final_output fo
LEFT JOIN warehouse wa ON fo.i_item_sk = wa.w_warehouse_sk
WHERE fo.sales_profit IS NOT NULL
ORDER BY fo.total_orders DESC, fo.sales_profit DESC
LIMIT 100 OFFSET 10;

