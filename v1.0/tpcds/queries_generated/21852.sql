
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        ws.ws_net_profit,
        COALESCE(ws.ws_net_paid_inc_tax / NULLIF(ws.ws_quantity, 0), 0) AS avg_price_per_unit,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        SUM(CASE WHEN rs.rn = 1 THEN rs.ws_net_profit ELSE 0 END) AS first_order_profit
    FROM RankedSales rs
    JOIN item ON rs.ws_item_sk = item.i_item_sk
    WHERE rs.sales_rank <= 20
    GROUP BY item.i_item_id, item.i_item_desc, item.i_current_price
)
SELECT 
    hpi.i_item_id,
    hpi.i_item_desc,
    hpi.i_current_price,
    hpi.total_orders,
    hpi.first_order_profit,
    CASE 
        WHEN hpi.total_orders > 10 THEN 'High Demand'
        WHEN hpi.total_orders IS NULL THEN 'No Sales'
        ELSE 'Moderate Demand'
    END AS demand_category,
    -- Incorporating an obscure semantic case for items with NULL first_order_profit
    CASE 
        WHEN hpi.first_order_profit IS NULL AND hpi.total_orders > 0 THEN 'First Sale Not Profitable'
        ELSE 'Profitable First Sale'
    END AS first_sale_performance
FROM HighProfitItems hpi
LEFT JOIN store_returns sr ON hpi.i_item_id = sr.sr_item_sk
WHERE hpi.total_orders > 0
ORDER BY hpi.first_order_profit DESC, hpi.total_orders DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
