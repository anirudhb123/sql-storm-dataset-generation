
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL

    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.cd_marital_status,
        sh.cd_purchase_estimate,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN customer c ON c.c_customer_sk = sh.c_customer_sk
    WHERE sh.level < 5  -- Limit hierarchy depth
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    JOIN sales_hierarchy sh ON ws.ws_bill_customer_sk = sh.c_customer_sk
    GROUP BY ws.ws_item_sk
),
ranked_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_revenue,
        RANK() OVER (ORDER BY sd.total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY sd.total_quantity DESC) AS quantity_rank
    FROM sales_data sd
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    r.total_quantity,
    r.total_revenue,
    CASE 
        WHEN r.revenue_rank = 1 THEN 'Top Revenue'
        WHEN r.quantity_rank = 1 THEN 'Top Quantity'
        ELSE 'Regular'
    END AS sale_rank
FROM ranked_sales r
JOIN item i ON r.ws_item_sk = i.i_item_sk
WHERE r.total_revenue IS NOT NULL
AND i.i_current_price > (
    SELECT AVG(i2.i_current_price) 
    FROM item i2 
    WHERE i2.i_item_sk IN (
        SELECT ws.ws_item_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_birth_year < 1980)
    )
)
OR r.total_quantity = (
    SELECT MAX(total_quantity) FROM ranked_sales
)
ORDER BY r.total_revenue DESC, r.total_quantity DESC
LIMIT 100;
