
WITH sales_analysis AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        1 AS level
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)

    UNION ALL

    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        sa.level + 1
    FROM catalog_sales cs
    JOIN sales_analysis sa ON cs.cs_item_sk = sa.ws_item_sk
    WHERE cs.cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)

SELECT
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_quantity) AS max_quantity,
    LISTAGG(DISTINCT i.i_item_desc, ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS item_descriptions
FROM sales_analysis sa
JOIN web_sales ws ON sa.ws_item_sk = ws.ws_item_sk AND sa.ws_order_number = ws.ws_order_number
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE ws.ws_sales_price > 0
AND ca.ca_state IS NOT NULL
GROUP BY ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_net_profit DESC;
