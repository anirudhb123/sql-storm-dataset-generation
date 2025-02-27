
WITH RECURSIVE customer_income AS (
    SELECT cd_demo_sk, 
           CASE 
               WHEN hd_income_band_sk IS NULL THEN 'unknown' 
               ELSE (SELECT CONCAT(CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) 
                     FROM income_band 
                     WHERE ib_income_band_sk = hd_income_band_sk) 
           END AS income_band,
           COUNT(c_customer_sk) AS customer_count
    FROM customer
    LEFT JOIN household_demographics ON c_current_hdemo_sk = hd_demo_sk
    GROUP BY cd_demo_sk, hd_income_band_sk
),
item_sales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sales, 
           AVG(ws_sales_price) AS average_price
    FROM web_sales
    GROUP BY ws_item_sk
),
returns_summary AS (
    SELECT cr_item_sk, 
           SUM(cr_return_quantity) AS total_returns,
           COUNT(DISTINCT cr_order_number) AS return_orders
    FROM catalog_returns
    GROUP BY cr_item_sk
),
advanced_sales AS (
    SELECT is_item_sk, 
           COALESCE(total_sales, 0) AS total_sales,
           COALESCE(total_returns, 0) AS total_returns,
           (COALESCE(total_sales, 0) - COALESCE(total_returns, 0)) AS net_sales
    FROM item_sales
    FULL OUTER JOIN returns_summary ON item_sales.ws_item_sk = returns_summary.cr_item_sk
),
sales_over_time AS (
    SELECT d_year, 
           SUM(net_sales) AS annual_sales
    FROM advanced_sales
    JOIN dates_dim ON d_date = current_date
    GROUP BY d_year
)
SELECT d_year, 
       annual_sales,
       RANK() OVER (ORDER BY annual_sales DESC) AS sales_rank,
       CASE 
           WHEN annual_sales = (SELECT MAX(annual_sales) FROM sales_over_time) THEN 'Highest' 
           ELSE 'Regular'
       END AS sales_status
FROM sales_over_time
WHERE annual_sales > (SELECT AVG(annual_sales) FROM sales_over_time)
ORDER BY d_year DESC;

