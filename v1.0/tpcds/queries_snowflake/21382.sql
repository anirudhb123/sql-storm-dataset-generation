
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458800 AND 2459845
),
FilteredSales AS (
    SELECT 
        RS.ws_item_sk,
        RS.ws_order_number,
        RS.ws_quantity,
        RS.ws_net_profit,
        COALESCE(SUM(SSR.ss_net_profit), 0) AS store_sales_profit,
        CASE 
            WHEN RS.ws_quantity IS NULL OR RS.ws_quantity = 0 THEN 'Zero or NULL Quantity'
            ELSE NULL
        END AS quantity_check
    FROM RankedSales RS
    LEFT JOIN store_sales SSR ON RS.ws_item_sk = SSR.ss_item_sk
        AND RS.ws_order_number = SSR.ss_ticket_number
    WHERE RS.profit_rank = 1
    GROUP BY RS.ws_item_sk, RS.ws_order_number, RS.ws_quantity, RS.ws_net_profit
),
FinalSales AS (
    SELECT 
        FS.ws_item_sk,
        FS.ws_order_number,
        FS.ws_quantity,
        FS.ws_net_profit,
        FS.store_sales_profit,
        CASE 
            WHEN FS.store_sales_profit > FS.ws_net_profit THEN 'Store Sales Higher'
            WHEN FS.store_sales_profit < FS.ws_net_profit THEN 'Web Sales Higher'
            ELSE 'Equal Profit'
        END AS profit_comparison,
        FS.quantity_check
    FROM FilteredSales FS
    WHERE FS.store_sales_profit IS NOT NULL
)

SELECT 
    FA.ws_item_sk,
    FA.ws_order_number,
    FA.ws_quantity,
    FA.ws_net_profit,
    FA.store_sales_profit,
    FA.profit_comparison,
    FA.quantity_check
FROM FinalSales FA
WHERE (FA.quantity_check IS NOT NULL OR FA.profit_comparison <> 'Equal Profit')
AND NOT EXISTS (
    SELECT * 
    FROM customer C 
    WHERE C.c_customer_sk = (SELECT MAX(ws_bill_customer_sk) FROM web_sales WHERE ws_item_sk = FA.ws_item_sk)
)
ORDER BY FA.ws_net_profit DESC, FA.store_sales_profit ASC;
