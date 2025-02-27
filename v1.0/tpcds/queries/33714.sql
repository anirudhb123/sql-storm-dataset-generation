
WITH RECURSIVE inventory_hierarchy AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand, 1 AS level
    FROM inventory
    WHERE inv_quantity_on_hand > 100
    UNION ALL
    SELECT inv.inv_date_sk, inv.inv_item_sk, inv.inv_warehouse_sk, inv.inv_quantity_on_hand, ih.level + 1
    FROM inventory inv
    JOIN inventory_hierarchy ih ON inv.inv_item_sk = ih.inv_item_sk
    WHERE inv.inv_quantity_on_hand < ih.inv_quantity_on_hand
), 
customer_sales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
),
sales_ranked AS (
    SELECT cs.c_customer_sk, cs.total_sales, cs.order_count,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
),
address_details AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer_address ca
    LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT sr.c_customer_sk, sr.total_sales, sr.order_count, sr.sales_rank,
       ad.ca_city, ad.ca_state, ad.ca_country, ad.total_orders,
       ih.inv_quantity_on_hand
FROM sales_ranked sr
JOIN address_details ad ON sr.c_customer_sk = ad.ca_address_sk
LEFT JOIN inventory_hierarchy ih ON sr.c_customer_sk = ih.inv_item_sk
WHERE sr.sales_rank <= 100
ORDER BY sr.sales_rank;
