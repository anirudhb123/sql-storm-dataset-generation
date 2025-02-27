
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS recursion_level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        sc.recursion_level + 1
    FROM web_sales ws
    JOIN SalesCTE sc ON ws.ws_order_number = sc.ws_order_number
    WHERE sc.recursion_level < 3
),
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        ais.ws_item_sk,
        ais.total_net_profit,
        ais.sales_count,
        ais.avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY ais.total_net_profit DESC) AS rank
    FROM AggregatedSales ais
)
SELECT 
    ci.i_item_id,
    ci.i_product_name,
    ti.total_net_profit,
    ti.sales_count,
    ti.avg_sales_price,
    (SELECT COUNT(*) FROM customer_demographics cd 
     WHERE cd.cd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000)) AS high_income_customers
FROM TopItems ti
JOIN item ci ON ti.ws_item_sk = ci.i_item_sk
WHERE ti.rank <= 10
ORDER BY ti.total_net_profit DESC;
