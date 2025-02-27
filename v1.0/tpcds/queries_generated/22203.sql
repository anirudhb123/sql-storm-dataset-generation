
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
        AND ws_quantity > (SELECT AVG(ws_quantity) FROM web_sales WHERE ws_bill_customer_sk IS NOT NULL)
),
customer_analysis AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CASE 
            WHEN cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd_marital_status
        END AS marital_status,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_marital_status
),
shipping_info AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_net_paid_inc_ship) AS total_shipping_revenue
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        sm.sm_type
    HAVING 
        total_shipping_revenue > 10000
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name,
    sa.total_spent,
    COUNT(CASE WHEN ra.total_ships > 0 THEN 1 END) AS active_shippers,
    s.total_shipping_revenue
FROM 
    customer_analysis ca
JOIN 
    customer c ON ca.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    ranked_sales ra ON c.c_customer_sk = ra.bill_customer_sk
JOIN 
    shipping_info s ON s.sm_type IS NOT NULL
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    LOWER(c.c_first_name) LIKE 'j%'
GROUP BY 
    ca.ca_city, ca.ca_state, c.c_first_name, c.c_last_name, sa.total_spent, s.total_shipping_revenue
HAVING 
    SUM(ca.total_spent) > 5000
ORDER BY 
    ca.ca_city, COUNT(DISTINCT c.c_customer_sk) DESC;
