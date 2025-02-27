
WITH RECURSIVE SalesData AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) as rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_ext_sales_price,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_net_profit DESC) as rn
    FROM catalog_sales
    WHERE cs_sold_date_sk < (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregatedSales AS (
    SELECT
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM SalesData
    GROUP BY ws_item_sk
),
RankedSales AS (
    SELECT
        a.ws_item_sk,
        a.total_orders,
        a.total_quantity,
        a.total_net_profit,
        DENSE_RANK() OVER (ORDER BY total_net_profit DESC) as rank
    FROM AggregatedSales a
    WHERE total_net_profit IS NOT NULL
)
SELECT
    i.i_item_id,
    i.i_product_name,
    r.total_orders,
    r.total_quantity,
    r.total_net_profit,
    r.rank
FROM RankedSales r
JOIN item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN store s ON s.s_store_sk = (
    SELECT ss_store_sk
    FROM store_sales 
    WHERE ss_item_sk = r.ws_item_sk
    ORDER BY ss_net_paid DESC
    LIMIT 1
)
WHERE r.rank <= 10
AND (r.total_quantity > 0 OR r.total_net_profit IS NOT NULL)
ORDER BY r.rank;
