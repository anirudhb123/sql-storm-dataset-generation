
WITH RECURSIVE Sales_Analysis AS (
    SELECT 
        ws.web_site_sk,
        ws.net_profit,
        COALESCE(SUM(cs.net_profit), 0) AS catalog_sales_profit,
        COALESCE(SUM(ss.net_profit), 0) AS store_sales_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.sold_date_sk DESC) AS row_num
    FROM web_sales ws
    LEFT JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY ws.web_site_sk, ws.net_profit
),
Recursive_CTE AS (
    SELECT 
        S.web_site_sk,
        S.net_profit,
        S.catalog_sales_profit,
        S.store_sales_profit,
        S.net_profit + S.catalog_sales_profit + S.store_sales_profit AS total_sales,
        ROW_NUMBER() OVER (ORDER BY (CASE WHEN S.total_sales IS NULL THEN 1 ELSE 0 END), S.total_sales DESC) AS rnk
    FROM Sales_Analysis S
)
SELECT 
    R.web_site_sk,
    R.total_sales AS total_revenue,
    CASE 
        WHEN R.total_sales IS NULL THEN 'No Revenue'
        WHEN R.total_sales < 1000 THEN 'Low Revenue'
        WHEN R.total_sales BETWEEN 1000 AND 10000 THEN 'Medium Revenue'
        ELSE 'High Revenue'
    END AS revenue_category
FROM Recursive_CTE R
WHERE R.rnk <= 5
ORDER BY R.total_sales DESC;

SELECT 
    DISTINCT A.ca_state,
    COALESCE(D.d_year, 0) AS 'Year',
    COUNT(C.c_customer_sk) AS customer_count,
    COUNT(DISTINCT CASE WHEN C.c_birth_month IS NULL THEN 1 END) AS month_missing_count
FROM customer C
JOIN customer_address A ON C.c_current_addr_sk = A.ca_address_sk
LEFT JOIN date_dim D ON C.c_first_sales_date_sk = D.d_date_sk
GROUP BY A.ca_state, D.d_year
HAVING COUNT(C.c_customer_sk) > 10
ORDER BY customer_count DESC, A.ca_state;
