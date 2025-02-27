
SELECT 
    C.c_customer_id,
    CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
    CA.ca_city,
    CA.ca_state,
    SUM(WS.ws_net_paid) AS total_spent,
    CASE 
        WHEN SUM(WS.ws_net_paid) > 1000 THEN 'High Value'
        WHEN SUM(WS.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COUNT(DISTINCT WS.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT CONCAT_WS(', ', I.i_item_desc), '; ') AS purchased_items
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
LEFT JOIN 
    item I ON WS.ws_item_sk = I.i_item_sk
WHERE 
    CA.ca_country = 'USA'
GROUP BY 
    C.c_customer_id, C.c_first_name, C.c_last_name, CA.ca_city, CA.ca_state
ORDER BY 
    total_spent DESC
LIMIT 100;
