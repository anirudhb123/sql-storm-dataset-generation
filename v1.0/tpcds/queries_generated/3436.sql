
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_per_item,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS overall_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price
),
TopItems AS (
    SELECT 
        item_rank.ws_item_sk,
        item_rank.ws_sales_price,
        item_rank.rank_per_item
    FROM 
        RankedSales item_rank
    WHERE 
        item_rank.rank_per_item = 1
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_sold_date_sk, ss.ss_item_sk
)
SELECT 
    a.warehouse_id,
    c.c_first_name,
    c.c_last_name,
    t.total_quantity,
    t.total_profit,
    COALESCE(NULLIF(t.total_profit, 0), 1) AS adjusted_profit,
    CONCAT('Item ', it.i_item_id, ' - ', it.i_item_desc) AS item_info
FROM 
    TopItems ti
LEFT JOIN 
    StoreSalesSummary t ON ti.ws_item_sk = t.ss_item_sk
JOIN 
    customer c ON c.c_customer_sk = t.ss_customer_sk
JOIN 
    warehouse a ON a.w_warehouse_sk = t.ss_item_sk % 5  -- mock condition for join
WHERE 
    t.total_quantity > 10
    AND adjusted_profit > 100
ORDER BY 
    t.total_profit DESC
LIMIT 50;
