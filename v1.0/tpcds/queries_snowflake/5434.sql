
WITH RankedItems AS (
    SELECT 
        i.i_item_id, 
        SUM(ss.ss_quantity) AS total_sold,
        SUM(ss.ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS rank
    FROM item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY i.i_item_id
),
TopItems AS (
    SELECT 
        r.i_item_id, 
        r.total_sold, 
        r.total_sales
    FROM RankedItems r
    WHERE r.rank <= 10
),
SalesDetails AS (
    SELECT 
        t.t_hour, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN TopItems ti ON ws.ws_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = ti.i_item_id)
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour
)
SELECT 
    t.t_hour, 
    COALESCE(td.total_quantity, 0) AS total_quantity,
    COALESCE(td.total_profit, 0) AS total_profit
FROM time_dim t
LEFT JOIN SalesDetails td ON t.t_hour = td.t_hour
ORDER BY t.t_hour;
