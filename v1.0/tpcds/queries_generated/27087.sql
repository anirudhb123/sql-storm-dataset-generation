
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_paid) AS average_order_value,
    STRING_AGG(DISTINCT CONCAT(p.p_promo_name, ' (', p.p_discount_active, ')') ORDER BY p.p_promo_name) AS applied_promotions,
    STRING_AGG(DISTINCT CONCAT(i.i_product_name, ' (', i.i_brand, ')') ORDER BY i.i_product_name) AS purchased_items
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE ca.ca_state IN ('CA', 'NY')
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY total_sales DESC, customer_name;
