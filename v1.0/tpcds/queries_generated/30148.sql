
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        1 AS level
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0

    UNION ALL

    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        sh.level + 1
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_order_number = sh.cs_order_number
    WHERE sh.level < 5
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_returns,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_returns,
    AVG(sh.cs_net_profit) AS avg_net_profit,
    RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN sales_hierarchy sh ON sh.cs_item_sk = ss.ss_item_sk
WHERE ca.ca_state = 'CA'
AND (c.c_birth_year BETWEEN 1980 AND 1990 OR c.c_email_address IS NOT NULL)
GROUP BY c.c_customer_id, ca.ca_city
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_store_sales DESC, ca.ca_city ASC;
