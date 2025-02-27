
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        1 AS depth
    FROM item i
    WHERE i.i_current_price IS NOT NULL

    UNION ALL

    SELECT 
        ih.i_item_sk,
        ih.i_item_id,
        ih.i_item_desc,
        ih.i_current_price,
        ih.i_brand,
        ih.i_category,
        depth + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.i_current_price < i.i_current_price
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    ROW_NUMBER() OVER(PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 
    (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022 AND d.d_month_seq BETWEEN 1 AND 12)
    AND 
    (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 12)
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_net_profit DESC
LIMIT 10;
