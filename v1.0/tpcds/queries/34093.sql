
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date, 0 AS depth
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
    
    UNION ALL
    
    SELECT d.d_date_sk, d.d_date, sd.depth + 1
    FROM date_dim d
    JOIN sales_dates sd ON d.d_date_sk = sd.d_date_sk - 1
    WHERE sd.depth < 30
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sale_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM sales_dates)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT customer_name, total_sales
    FROM sales_summary
    WHERE sale_rank <= 10
),
return_summary AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
final_summary AS (
    SELECT 
        tc.customer_name,
        tc.total_sales,
        COALESCE(rs.total_return_amount, 0) AS total_return,
        (tc.total_sales - COALESCE(rs.total_return_amount, 0)) AS net_sales
    FROM top_customers tc
    LEFT JOIN return_summary rs ON rs.sr_returned_date_sk IN (SELECT d_date_sk FROM sales_dates)
)
SELECT 
    fs.customer_name,
    fs.total_sales,
    fs.total_return,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales > 1000 THEN 'High Value' 
        WHEN fs.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value
FROM final_summary fs
ORDER BY fs.net_sales DESC;
