
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) as rn
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
), SalesSummary AS (
    SELECT 
        item.i_item_id,
        COUNT(DISTINCT ss_ticket_number) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit,
        (SELECT AVG(ws_net_profit)
         FROM web_sales
         WHERE ws_item_sk = item.i_item_sk AND ws_net_profit IS NOT NULL) AS avg_web_profit,
        SUM(RCASE WHEN ws_net_profit IS NULL THEN 0 ELSE ws_net_profit END) AS net_profit_with_null_handling
    FROM item 
    LEFT JOIN store_sales ON item.i_item_sk = store_sales.ss_item_sk 
    LEFT JOIN RecursiveSales ON item.i_item_sk = RecursiveSales.ws_item_sk
    GROUP BY item.i_item_id
), ItemRanked AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_store_profit DESC) AS profit_rank
    FROM SalesSummary
)
SELECT 
    ir.i_item_id,
    ir.total_store_sales,
    ir.total_store_profit,
    ir.avg_web_profit,
    CASE 
        WHEN ir.avg_web_profit > ir.total_store_profit THEN 'Underperforming'
        WHEN ir.avg_web_profit < ir.total_store_profit THEN 'Overperforming'
        ELSE 'In-line'
    END AS performance_status,
    COALESCE(ir.net_profit_with_null_handling, 0) AS adjusted_net_profit,
    RANK() OVER (ORDER BY COALESCE(ir.net_profit_with_null_handling, 0) DESC) AS rank_by_profit
FROM ItemRanked ir
WHERE ir.profit_rank <= 10
ORDER BY ir.total_store_profit DESC, ir.i_item_id;
