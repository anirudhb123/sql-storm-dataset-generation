
WITH Customer_Overview AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value,
        STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used
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
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
),
Order_Summary AS (
    SELECT 
        cu.full_name,
        cu.ca_city,
        cu.ca_state,
        COUNT(DISTINCT o.ws_order_number) AS order_count,
        SUM(o.ws_sales_price) AS total_revenue,
        AVG(o.ws_sales_price) AS avg_order_value
    FROM 
        Customer_Overview cu
    LEFT JOIN 
        web_sales o ON cu.c_customer_id = o.ws_bill_customer_sk
    GROUP BY 
        cu.full_name, cu.ca_city, cu.ca_state
)
SELECT 
    O.full_name,
    O.ca_city,
    O.ca_state,
    O.order_count,
    O.total_revenue,
    O.avg_order_value,
    CASE 
        WHEN O.total_revenue >= 1000 THEN 'High Value'
        WHEN O.total_revenue BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    Order_Summary O
ORDER BY 
    total_revenue DESC
LIMIT 10;
