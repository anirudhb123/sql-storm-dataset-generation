
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand, 1 AS level
    FROM item
    WHERE i_item_sk < 1000  -- Example condition to filter items

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price * 0.9 AS i_current_price, i.i_brand, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.level < 3
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
price_statistics AS (
    SELECT 
        i_brand,
        AVG(i_current_price) AS avg_price,
        MIN(i_current_price) AS min_price,
        MAX(i_current_price) AS max_price
    FROM item
    GROUP BY i_brand
),
final_results AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.order_count,
        cd.total_spent,
        ps.avg_price,
        ps.min_price,
        ps.max_price,
        CASE 
            WHEN cd.total_spent > ps.avg_price THEN 'Above Average'
            ELSE 'Below Average'
        END AS spending_category
    FROM customer_data cd
    CROSS JOIN price_statistics ps
)

SELECT 
    fh.*,
    ih.i_item_desc,
    ih.i_current_price
FROM final_results fh
LEFT OUTER JOIN item_hierarchy ih ON fh.total_spent BETWEEN ih.i_current_price * 0.8 AND ih.i_current_price * 1.2
WHERE fh.order_count > 0
ORDER BY fh.total_spent DESC, fh.c_last_name, fh.c_first_name
LIMIT 100;
