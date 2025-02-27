
WITH RECURSIVE sales_data AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_sales_price * ws_quantity) AS total_sales,
           ws_sold_date_sk
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
daily_sales AS (
    SELECT d.d_date, 
           COALESCE(SUM(sd.total_quantity), 0) AS total_quantity,
           COALESCE(SUM(sd.total_sales), 0) AS total_sales
    FROM date_dim d
    LEFT JOIN sales_data sd ON d.d_date_sk = sd.ws_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date
),
average_sales AS (
    SELECT d.d_date, 
           ds.total_quantity,
           ds.total_sales,
           AVG(ds.total_sales) OVER (ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_sales_last_7_days
    FROM daily_sales ds
    JOIN date_dim d ON ds.d_date = d.d_date
),
high_sales_dates AS (
    SELECT d.d_date, 
           total_quantity, 
           total_sales, 
           avg_sales_last_7_days
    FROM average_sales
    WHERE total_sales > avg_sales_last_7_days
)
SELECT hsd.d_date, 
       hsd.total_quantity, 
       hsd.total_sales, 
       CASE 
           WHEN hsd.total_quantity IS NULL THEN 'No sales' 
           ELSE 'Sales occurred'
       END AS sales_status,
       ROW_NUMBER() OVER (ORDER BY hsd.d_date) AS sales_rank,
       COALESCE(item_details.i_item_desc, 'Unknown Item') AS item_description
FROM high_sales_dates hsd
LEFT JOIN item item_details ON hsd.ws_item_sk = item_details.i_item_sk
ORDER BY hsd.d_date;
