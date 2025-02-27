
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_customer_id = (SELECT MIN(c_customer_id) FROM customer)
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk AND ch.level < 3
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    ca.ca_address_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    d.d_date AS transaction_date,
    ISNULL(iss.total_quantity_sold, 0) AS sold_quantity,
    COALESCE(isn.average_sales_price, 0) AS avg_price,
    CASE 
        WHEN issu.c_current_cdemo_sk IS NOT NULL THEN 'Repeat Customer'
        ELSE 'New Customer'
    END AS customer_type,
    SUM(ss.ss_net_profit) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_address_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM customer_address ca
INNER JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
LEFT JOIN item_stats isn ON ss.ss_item_sk = isn.i_item_sk
LEFT JOIN customer_hierarchy issu ON c.c_current_cdemo_sk = issu.c_current_cdemo_sk
GROUP BY 
    ca.ca_address_sk, c.c_first_name, c.c_last_name, d.d_date, issu.c_current_cdemo_sk
HAVING SUM(ss.ss_net_profit) >= 1000
ORDER BY total_profit DESC
LIMIT 100;
