
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
AggregatedSales AS (
    SELECT 
        sd.ws_item_sk, 
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales, 
        SUM(sd.ws_net_profit) AS total_profit
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
),
TopSales AS (
    SELECT 
        as.ws_item_sk,
        as.total_sales,
        RANK() OVER (ORDER BY as.total_sales DESC) AS sales_rank
    FROM AggregatedSales as
    WHERE as.total_sales > 1000
)
SELECT 
    item.i_item_id,
    item.i_item_desc, 
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.total_profit, 0) AS total_profit,
    COALESCE(ts.sales_rank, 'N/A') AS sales_rank,
    CASE 
        WHEN ts.sales_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM item
LEFT JOIN TopSales ts ON item.i_item_sk = ts.ws_item_sk
WHERE item.i_current_price IS NOT NULL
ORDER BY total_sales DESC;
