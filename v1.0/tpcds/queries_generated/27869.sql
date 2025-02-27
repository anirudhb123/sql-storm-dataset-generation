
WITH CustomerProduct AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        i.i_product_name,
        i.i_item_desc,
        ws.ws_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
),
CityProductCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS product_count
    FROM 
        CustomerProduct
    GROUP BY 
        ca_city, ca_state
),
CityTopProducts AS (
    SELECT 
        cp.ca_city,
        cp.ca_state,
        cp.i_product_name,
        ROW_NUMBER() OVER (PARTITION BY cp.ca_city, cp.ca_state ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        CustomerProduct cp
    GROUP BY 
        cp.ca_city, cp.ca_state, cp.i_product_name
)
SELECT 
    ct.ca_city,
    ct.ca_state,
    ct.i_product_name,
    COUNT(*) AS customer_count,
    SUM(ws_net_profit) AS total_profit
FROM 
    CustomerProduct cp
JOIN 
    CityProductCounts ct ON cp.ca_city = ct.ca_city AND cp.ca_state = ct.ca_state
JOIN 
    CityTopProducts tp ON cp.ca_city = tp.ca_city AND cp.ca_state = tp.ca_state AND tp.rank <= 3
GROUP BY 
    ct.ca_city, ct.ca_state, ct.i_product_name
ORDER BY 
    ct.ca_city, ct.ca_state, total_profit DESC;
