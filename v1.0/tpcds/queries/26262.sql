
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    SUM(wr.wr_return_amt) AS total_returned_amt,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.cd_credit_rating) AS top_credit_rating,
    STRING_AGG(DISTINCT CONCAT(p.p_promo_name, ' (', p.p_promo_id, ')'), ', ') AS used_promotions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state = 'CA' AND
    ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    customer_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 50;
