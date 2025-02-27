
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.ss_sold_date_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_sales,
        sh.level + 1 AS level
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales s ON sh.s_store_sk = s.s_store_sk AND sh.ss_sold_date_sk = s.ss_sold_date_sk
    WHERE 
        sh.level < 3
    GROUP BY 
        sh.s_store_sk, sh.ss_sold_date_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
promotional_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COALESCE(promo.total_sales, 0) AS total_promotional_sales,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    AVG(CASE WHEN cd.rank_gender <= 10 THEN cd.cd_purchase_estimate END) AS avg_top_customers_purchase
FROM 
    customer_address ca
LEFT JOIN 
    store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
LEFT JOIN 
    customer_details cd ON ss.ss_customer_sk = cd.c_customer_sk
LEFT JOIN 
    promotional_sales promo ON ss.ss_item_sk = promo.ws_item_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_quantity) > 100
ORDER BY 
    total_sales_quantity DESC
LIMIT 100;
