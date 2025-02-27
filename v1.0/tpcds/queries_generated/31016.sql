
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_ext_sales_price) AS total_sales, 
           1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk

    UNION ALL

    SELECT ws.bill_customer_sk, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           s.level + 1
    FROM web_sales ws
    JOIN sales_hierarchy s ON ws.ws_bill_customer_sk = s.customer_sk
    GROUP BY ws.bill_customer_sk
)
SELECT c.c_customer_id,
       COALESCE(d.cd_gender, 'Unknown') AS gender,
       COALESCE(a.ca_city, 'Not Available') AS city,
       SUM(h.total_sales) AS total_sales,
       COUNT(DISTINCT CASE WHEN ws.web_site_sk IS NOT NULL THEN ws.ws_order_number END) AS online_orders,
       COUNT(DISTINCT CASE WHEN ss.s_store_sk IS NOT NULL THEN ss.ss_ticket_number END) AS store_orders,
       ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(h.total_sales) DESC) AS sales_rank
FROM customer c
LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN sales_hierarchy h ON c.c_customer_sk = h.customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c.c_customer_id, d.cd_gender, a.ca_city
HAVING SUM(h.total_sales) > 1000
ORDER BY total_sales DESC
LIMIT 10;
