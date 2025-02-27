
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS sales_3_day_sum
    FROM web_sales ws
),
item_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
sold_items AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sold,
        MAX(cs.cs_sold_date_sk) AS last_sold_date
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT 
    ia.ca_state,
    ia.total_quantity AS total_inventory,
    COALESCE(s.total_sold, 0) AS total_sold,
    COALESCE(s.total_sold, 0) / NULLIF(ia.total_quantity, 0) AS sell_through_rate,
    MAX(rs.ws_sales_price) AS max_sales_price,
    MIN(rs.ws_sales_price) AS min_sales_price,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    CASE 
        WHEN COUNT(DISTINCT rs.ws_order_number) = 0 THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NULL) AS null_customers_count,
    COUNT(DISTINCT rs.ws_item_sk) FILTER (WHERE rs.price_rank = 1) AS top_priced_item_count
FROM item_inventory ia
LEFT OUTER JOIN sold_items s ON ia.inv_item_sk = s.cs_item_sk
LEFT JOIN ranked_sales rs ON ia.inv_item_sk = rs.ws_item_sk
JOIN customer_address addr ON addr.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = s.cs_bill_customer_sk LIMIT 1)
WHERE 
    ia.total_quantity > 0
    AND (s.total_sold IS NULL OR s.last_sold_date > (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_year = 2022))
GROUP BY ia.ca_state
HAVING (sell_through_rate IS NULL OR sell_through_rate > 0.5)
   AND (AVG(rs.ws_sales_price) IS NOT NULL AND AVG(rs.ws_sales_price) < 100)
ORDER BY ia.ca_state;
