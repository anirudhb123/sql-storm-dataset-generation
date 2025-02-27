
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(inventory.inv_quantity_on_hand) AS max_inventory
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    inventory ON ws.ws_item_sk = inventory.inv_item_sk
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state, cd.cd_gender
ORDER BY 
    total_profit DESC
LIMIT 100;
