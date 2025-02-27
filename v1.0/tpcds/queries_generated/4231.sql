
WITH Expensive_Items AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY i_current_price DESC) AS rn
    FROM item
    WHERE i_current_price > (SELECT AVG(i_current_price) FROM item)
),
Customer_Purchases AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
High_Value_Customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cp.total_spent,
        cp.total_orders
    FROM customer AS c
    JOIN Customer_Purchases AS cp ON c.c_customer_sk = cp.ws_bill_customer_sk
    WHERE cp.total_spent > 1000
),
Customer_Locations AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address AS ca
    LEFT JOIN customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
Top_Cities AS (
    SELECT 
        ca_city,
        ca_state,
        SUM(customer_count) AS total_customers
    FROM Customer_Locations
    GROUP BY ca_city, ca_state
    HAVING SUM(customer_count) > 10
)

SELECT 
    hic.c_first_name,
    hic.c_last_name,
    e.i_item_desc,
    e.i_current_price,
    tc.ca_city,
    tc.ca_state,
    ROW_NUMBER() OVER (PARTITION BY hic.c_customer_sk ORDER BY e.i_current_price DESC) AS ranking,
    COALESCE(e.i_current_price * hic.total_orders, 0) AS estimated_revenue
FROM High_Value_Customers AS hic
JOIN Expensive_Items AS e ON e.i_item_sk IN (
    SELECT DISTINCT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_customer_sk = hic.c_customer_sk
)
JOIN Top_Cities AS tc ON hic.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk 
    FROM web_sales
    WHERE ws_ship_customer_sk IS NOT NULL
)
ORDER BY estimated_revenue DESC
LIMIT 50;
