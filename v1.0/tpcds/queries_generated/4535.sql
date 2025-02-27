
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10010
    GROUP BY 
        ws.ws_item_sk
), 
customer_spend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
promotion_data AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_sales) AS promo_sales
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sd.total_net_profit) AS city_total_net_profit,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    AVG(cs.total_spent) AS avg_customer_spending,
    MAX(pd.promo_sales) AS highest_promo_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    sales_data sd ON c.c_customer_sk = sd.ws_item_sk
JOIN 
    customer_spend cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    promotion_data pd ON pd.p_promo_sk = sd.ws_item_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (ca.ca_city LIKE 'San%' OR ca.ca_city LIKE 'Los%')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(sd.total_net_profit) > 1000
ORDER BY 
    city_total_net_profit DESC;
