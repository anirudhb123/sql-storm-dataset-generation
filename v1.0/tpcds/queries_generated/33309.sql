
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
date_range AS (
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
total_sales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_sold_date_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(ss.ss_ticket_number) AS total_sales_tickets,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_range d)
    GROUP BY ss.ss_store_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ts.total_sales) AS total_web_sales,
    COALESCE(SUM(sss.total_net_profit), 0) AS total_store_net_profit,
    STRING_AGG(CONCAT(ch.c_first_name, ' ', ch.c_last_name), '; ') AS customer_related
FROM customer_address ca
LEFT JOIN total_sales ts ON EXISTS (
    SELECT 1 
    FROM web_sales ws 
    WHERE ws.ws_bill_addr_sk = ca.ca_address_sk 
      AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_range d)
)
LEFT JOIN store_sales_summary sss ON sss.ss_store_sk IN (
    SELECT s.s_store_sk 
    FROM store s 
    WHERE s.s_city = ca.ca_city AND s.s_state = ca.ca_state
)
LEFT JOIN customer_hierarchy ch ON ch.c_customer_sk = ca.ca_address_sk
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(ts.total_sales) > 10000 OR COALESCE(SUM(sss.total_net_profit), 0) > 5000
ORDER BY TOTAL_WEB_SALES DESC, TOTAL_STORE_NET_PROFIT DESC;
