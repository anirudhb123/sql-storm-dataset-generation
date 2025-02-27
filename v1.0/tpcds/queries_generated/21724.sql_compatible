
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promotions
    FROM 
        promotion p
    GROUP BY 
        p.p_promo_id
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS purchase_count,
        SUM(ws_sales_price) AS total_spent,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_sales_price) AS median_spending
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(cs.total_sales) AS total_online_sales,
    SUM(cs.total_orders) AS total_online_orders,
    ps.p_promo_id AS promo_id,
    ps.promo_count,
    ca.ca_state
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    sales_data cs ON cs.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk = c.c_customer_sk)
LEFT JOIN 
    promotion_summary ps ON ps.promo_count > 0
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ps.p_promo_id, ps.promo_count, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10 
    AND SUM(cs.total_sales) IS NOT NULL
ORDER BY 
    num_customers DESC, total_online_sales DESC;
