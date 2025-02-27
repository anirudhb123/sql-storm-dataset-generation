
WITH RECURSIVE CustomerCTE AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_first_sales_date_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_gender ORDER BY c.c_birth_year) AS gender_rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
),
SalesData AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
ItemSales AS (
    SELECT i.i_item_sk, 
           i.i_item_id, 
           i.i_product_name,
           COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
           COALESCE(sd.total_sales, 0) AS total_sales_value
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
),
WarehouseStats AS (
    SELECT w.w_warehouse_sk, 
           COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM warehouse w
    JOIN store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY w.w_warehouse_sk
)
SELECT ccte.c_customer_sk, 
       ccte.c_first_name || ' ' || ccte.c_last_name AS full_name,
       isales.i_item_id, 
       isales.i_product_name,
       isales.total_quantity_sold,
       isales.total_sales_value,
       ROW_NUMBER() OVER (PARTITION BY ccte.c_customer_sk ORDER BY isales.total_sales_value DESC) AS sales_rank,
       wstats.distinct_items_sold,
       wstats.total_net_profit
FROM CustomerCTE ccte
JOIN ItemSales isales ON ccte.c_customer_sk = isales.i_item_sk
LEFT JOIN WarehouseStats wstats ON wstats.w_warehouse_sk = (
    SELECT TOP 1 w.w_warehouse_sk
    FROM warehouse w
    ORDER BY w.w_warehouse_name
)
WHERE isales.total_sales_value > 0
AND ccte.gender_rn <= 5
ORDER BY ccte.c_customer_sk, isales.total_sales_value DESC;
