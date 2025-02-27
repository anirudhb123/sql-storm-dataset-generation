
WITH ProcessedData AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used
    FROM 
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
)
SELECT 
    customer_full_name,
    ca_city,
    ca_state,
    cd_gender,
    total_orders,
    total_spent,
    promotions_used,
    LENGTH(promotions_used) AS promo_count_chars,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    ProcessedData
WHERE 
    customer_full_name LIKE 'A%'
ORDER BY 
    total_spent DESC;
