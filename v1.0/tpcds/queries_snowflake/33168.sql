
WITH RECURSIVE category_hierarchy AS (
    SELECT i_category_id, i_category, i_class_id, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT DISTINCT cs_item_sk FROM catalog_sales WHERE cs_sold_date_sk = 20230101)
    UNION ALL
    SELECT i.i_category_id, i.i_category, i.i_class_id, ch.level + 1
    FROM item i
    JOIN category_hierarchy ch ON i.i_class_id = ch.i_class_id
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count, 
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    AVG(ws.ws_list_price) AS avg_list_price,
    MAX(ws.ws_net_profit) AS max_net_profit,
    LISTAGG(i.i_item_desc, ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS item_descriptions,
    CASE 
        WHEN SUM(ws.ws_ship_date_sk) IS NULL THEN 'No Shipments'
        ELSE 'Has Shipments'
    END AS shipment_status
FROM
    customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE
    ca.ca_state = 'NY'
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk BETWEEN 20230101 AND 20230131
    )
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY
    total_sales DESC
LIMIT 10;
