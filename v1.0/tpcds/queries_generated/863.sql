
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk, ws_order_number
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_profit
    FROM SalesData sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.rn = 1
)
SELECT 
    t_year,
    SUM(total_quantity) AS year_total_quantity,
    AVG(total_profit) AS average_profit
FROM (
    SELECT 
        date_dim.d_year,
        sales.total_quantity,
        sales.total_profit
    FROM TopSales sales
    JOIN date_dim ON sales.ws_order_number IN (
        SELECT ss_ticket_number 
        FROM store_sales
    )
    WHERE date_dim.d_date_sk = sales.ws_order_number
) AS YearlySales
GROUP BY t_year
ORDER BY t_year ASC;
