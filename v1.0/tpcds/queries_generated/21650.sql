
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX')
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cd.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(NULLIF(cd.cd_gender, 'M'), 'Unknown') AS gender_label,
    CASE 
        WHEN cs.order_count > 5 THEN 'Frequent Buyer'
        WHEN cs.order_count BETWEEN 1 AND 5 THEN 'Occasional Buyer'
        ELSE 'Non Buyer'
    END AS customer_type,
    MAX(CASE 
        WHEN cd.cd_marital_status = 'M' THEN 1
        ELSE 0 
    END) OVER (PARTITION BY cd.ca_city) AS city_married_count
FROM ranked_sales cs
JOIN customer_details cd ON cs.ws_item_sk = cd.c_customer_id
LEFT JOIN inventory i ON i.inv_item_sk = cs.ws_item_sk 
WHERE i.inv_quantity_on_hand IS NOT NULL 
AND i.inv_warehouse_sk IN (
    SELECT w_warehouse_sk 
    FROM warehouse 
    WHERE w_country = 'USA' AND w_state = 'CA'
) 
ORDER BY cs.total_sales DESC, cd.ca_city ASC
LIMIT 100
OFFSET 0;
