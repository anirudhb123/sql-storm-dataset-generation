
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c_current_addr_sk,
           1 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk 
    WHERE ch.level < 3
), inventory_summary AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY inv.inv_item_sk
), sales_summary AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales,
           SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws.ws_item_sk
), return_summary AS (
    SELECT sr.si_item_sk, COUNT(*) AS total_returns,
           SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IS NOT NULL
    GROUP BY sr.sr_item_sk
)
SELECT c.c_first_name, c.c_last_name, ca.ca_city,
       COALESCE(sales.total_sales, 0) AS total_sales,
       COALESCE(inventory.total_quantity, 0) AS total_quantity,
       COALESCE(returns.total_returns, 0) AS total_returns,
       COALESCE(returns.total_return_amount, 0) AS total_return_amount,
       ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY total_sales DESC) AS sales_rank
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_summary sales ON c.c_customer_sk = sales.ws_item_sk
LEFT JOIN inventory_summary inventory ON sales.ws_item_sk = inventory.inv_item_sk
LEFT JOIN return_summary returns ON sales.ws_item_sk = returns.si_item_sk
WHERE ca.ca_state = 'CA' OR ca.ca_state IS NULL
ORDER BY total_sales DESC, total_quantity DESC
FETCH FIRST 100 ROWS ONLY;
