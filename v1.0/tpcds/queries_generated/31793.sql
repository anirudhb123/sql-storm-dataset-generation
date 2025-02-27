
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS hierarchy_level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_current_addr_sk = c.c_current_addr_sk
    WHERE ch.hierarchy_level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM item i
    JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE sd.total_quantity > 100
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    CASE 
        WHEN hh.hd_income_band_sk IS NOT NULL 
        THEN 'Income Band'
        ELSE 'No Income Band' 
    END AS income_band_status
FROM CustomerHierarchy ch
LEFT JOIN household_demographics hh ON hh.hd_demo_sk = ch.c_customer_sk
JOIN TopItems ti ON ch.c_current_addr_sk = ti.i_item_sk
WHERE EXISTS (
    SELECT 1 
    FROM store s 
    WHERE s.s_store_sk = ch.c_current_addr_sk
) AND ti.sales_rank <= 10
ORDER BY ti.total_sales DESC, ch.hierarchy_level, ch.c_last_name;
