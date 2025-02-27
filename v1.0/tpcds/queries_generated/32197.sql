
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk
),
AddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address
    INNER JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state
),
TopProducts AS (
    SELECT 
        i_item_id,
        i_item_desc,
        total_quantity,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_profit
          FROM web_sales
          GROUP BY ws_item_sk) AS sales_summary
    INNER JOIN item ON sales_summary.ws_item_sk = i_item_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT a.ca_address_sk) AS unique_addresses,
    p.i_item_id,
    p.i_item_desc,
    COALESCE(SUM(s.total_profit), 0) AS total_profit,
    MAX(s.total_quantity) AS max_quantity_per_order
FROM AddressCTE AS a
LEFT JOIN SalesCTE AS s ON s.ws_item_sk IN (SELECT i_item_sk 
                                              FROM TopProducts 
                                              WHERE rank <= 10)
LEFT JOIN item AS p ON s.ws_item_sk = p.i_item_sk
GROUP BY a.ca_city, a.ca_state, p.i_item_id, p.i_item_desc
HAVING COUNT(DISTINCT a.ca_address_sk) > 1
ORDER BY total_profit DESC;
