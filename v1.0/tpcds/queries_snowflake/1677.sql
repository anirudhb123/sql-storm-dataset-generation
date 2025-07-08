
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
StoreInfo AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales
    FROM store_sales
    GROUP BY ss_store_sk
),
HighProfitItems AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        item.i_current_price,
        RankedSales.total_quantity_sold,
        RankedSales.total_net_profit
    FROM RankedSales
    JOIN item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE RankedSales.profit_rank <= 10
),
TopStores AS (
    SELECT
        StoreInfo.ss_store_sk,
        StoreInfo.total_store_profit,
        StoreInfo.total_sales
    FROM StoreInfo
    WHERE StoreInfo.total_store_profit > (
        SELECT AVG(total_store_profit) FROM StoreInfo
    )
)
SELECT
    TopStores.ss_store_sk,
    TopStores.total_store_profit,
    TopStores.total_sales,
    COALESCE(HighProfitItems.i_product_name, 'No High Profit Items') AS high_profit_item_name,
    COALESCE(HighProfitItems.total_net_profit, 0) AS high_profit_item_net_profit
FROM TopStores
LEFT JOIN HighProfitItems ON TopStores.ss_store_sk = (
    SELECT ss_store_sk 
    FROM store 
    WHERE ss_store_sk IN (
        SELECT DISTINCT ss_store_sk 
        FROM store_sales 
        WHERE ss_item_sk IN (SELECT ws_item_sk FROM web_sales)
    )
    LIMIT 1
)
ORDER BY TopStores.total_store_profit DESC;
