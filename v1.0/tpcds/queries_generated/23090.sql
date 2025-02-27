
WITH daily_sales AS (
    SELECT d.d_date, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY d.d_date
), ranked_sales AS (
    SELECT d.d_date, 
           total_sales,
           total_orders,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM daily_sales d
), return_sales AS (
    SELECT d.d_date,
           SUM(sr.sr_return_amount) AS total_returns
    FROM date_dim d
    LEFT JOIN store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk
    WHERE d.d_date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY d.d_date
), adjusted_sales AS (
    SELECT r.d_date,
           r.total_sales,
           r.total_orders,
           COALESCE(r.total_sales, 0) - COALESCE(rs.total_returns, 0) AS net_sales
    FROM ranked_sales r
    LEFT JOIN return_sales rs ON r.d_date = rs.d_date
)
SELECT 
    a.d_date, 
    a.total_sales, 
    a.total_orders, 
    a.net_sales,
    CASE 
        WHEN a.net_sales < 0 THEN 'Loss'
        WHEN a.net_sales BETWEEN 1 AND 500 THEN 'Low Profit'
        WHEN a.net_sales BETWEEN 501 AND 1000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM adjusted_sales a
WHERE a.net_sales IS NOT NULL 
AND EXISTS (
    SELECT 1 
    FROM customer c 
    WHERE c.c_current_addr_sk IS NOT NULL 
    AND c.c_current_cdemo_sk IN (
        SELECT cd_demo_sk 
        FROM customer_demographics cd 
        WHERE cd.cd_gender = 'F' 
        AND cd.cd_marital_status = (SELECT MAX(cd_marital_status) FROM customer_demographics)
    )
)
ORDER BY a.net_sales DESC
LIMIT 10;
