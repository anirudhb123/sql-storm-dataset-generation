
WITH RECURSIVE date_series AS (
    SELECT MIN(d_date_sk) AS d_date_sk
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT d_date_sk + 1
    FROM date_dim dd
    JOIN date_series ds ON ds.d_date_sk + 1 = dd.d_date_sk
    WHERE dd.d_year = 2023
), sales_data AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales
    WHERE ws_ship_date_sk IN (SELECT d_date_sk FROM date_series)
    GROUP BY ws_ship_date_sk
), return_data AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns 
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_series)
    GROUP BY sr_returned_date_sk
), combined_data AS (
    SELECT 
        ds.d_date_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_quantity, 0) AS total_quantity
    FROM date_series ds
    LEFT JOIN sales_data sd ON ds.d_date_sk = sd.ws_ship_date_sk
    LEFT JOIN return_data rd ON ds.d_date_sk = rd.sr_returned_date_sk
)
SELECT 
    d.d_date_sk,
    d.total_sales,
    d.total_returns,
    d.total_orders,
    d.total_quantity,
    (d.total_sales - d.total_returns) AS net_sales,
    ROUND(d.total_sales * 100.0 / NULLIF(d.total_orders, 0), 2) AS avg_sales_per_order,
    COUNT(cd.customer_id) AS total_customers,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM combined_data d
LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY d.d_date_sk, d.total_sales, d.total_returns, d.total_orders, d.total_quantity
ORDER BY d.d_date_sk DESC
LIMIT 30;
