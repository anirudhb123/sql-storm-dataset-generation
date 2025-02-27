
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
),
FilteredSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        sh.total_orders,
        (CASE 
            WHEN sh.total_profit IS NULL THEN 0
            ELSE sh.total_profit END) AS profit_adjusted
    FROM SalesHierarchy sh
    WHERE sh.rank <= 10
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    WHERE ws.ws_net_profit >= (
        SELECT AVG(ws_inner.ws_net_profit) 
        FROM web_sales ws_inner
    )
    GROUP BY ws.ws_item_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_profit,
    f.total_orders,
    pi.total_quantity_sold,
    (SELECT COUNT(DISTINCT wr.wr_order_number) 
     FROM web_returns wr 
     WHERE wr.wr_returning_customer_sk = f.c_customer_sk) AS total_returns,
    DENSE_RANK() OVER (ORDER BY f.total_profit DESC) AS profit_rank
FROM FilteredSales f
LEFT JOIN PopularItems pi ON pi.ws_item_sk IN (
    SELECT inv.inv_item_sk 
    FROM inventory inv 
    WHERE inv.inv_quantity_on_hand > 50
)
ORDER BY f.total_profit DESC, f.c_last_name, f.c_first_name;
