
SELECT 
    CA.ca_city,
    CA.ca_state,
    COUNT(DISTINCT C.c_customer_id) AS total_customers,
    AVG(CD.cd_purchase_estimate) AS average_purchase_estimate,
    CASE 
        WHEN AVG(CD.cd_purchase_estimate) > 1000 THEN 'High Spender'
        ELSE 'Low Spender'
    END AS spender_category,
    STRING_AGG(DISTINCT W.w_warehouse_name, ', ') AS warehouses_contributing,
    STRING_AGG(DISTINCT I.i_product_name, ', ') AS stocked_items
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
JOIN 
    web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
JOIN 
    item I ON WS.ws_item_sk = I.i_item_sk
JOIN 
    store S ON WS.ws_ship_addr_sk = S.s_store_sk
JOIN 
    warehouse W ON S.s_store_sk = W.w_warehouse_sk
WHERE 
    CA.ca_state = 'CA'
GROUP BY 
    CA.ca_city, CA.ca_state
ORDER BY 
    total_customers DESC, average_purchase_estimate DESC;
