
SELECT 
    ca_city AS city,
    ca_state AS state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
    SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales,
    MIN(w.w_warehouse_name) AS warehouse_name,
    MAX(d.d_date) AS max_order_date
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk OR w.w_warehouse_sk = ss.ss_store_sk
JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk OR d.d_date_sk = ss.ss_sold_date_sk
WHERE (ca_city IS NOT NULL AND ca_state IS NOT NULL)
GROUP BY ca_city, ca_state
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY total_web_sales DESC, customer_count DESC;
