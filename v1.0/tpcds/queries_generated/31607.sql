
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 1000
), 
CustomerCTE AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_customer_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk
), 
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        COUNT(ws.ws_ship_mode_sk) AS order_count
    FROM 
        web_sales AS ws
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id, sm.sm_carrier
    HAVING 
        COUNT(ws.ws_ship_mode_sk) > 50
)
SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_sk) AS active_customers,
    SUM(COALESCE(cc.total_customer_spent, 0)) AS total_spent_by_customers,
    AVG(cc.total_orders) AS avg_orders_per_customer,
    COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_shipping_methods,
    MAX(sales.total_sales) AS max_sales_per_item
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerCTE AS cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN 
    SalesCTE AS sales ON sales.ws_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk
    )
JOIN 
    ShippingModes AS sm ON sm.order_count > 50
WHERE 
    ca.ca_country IS NOT NULL 
GROUP BY 
    ca.ca_country
ORDER BY 
    total_spent_by_customers DESC
LIMIT 10;
