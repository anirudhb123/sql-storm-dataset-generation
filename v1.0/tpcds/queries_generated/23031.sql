
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ranked_customers AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 1000 THEN 'VIP'
            WHEN total_spent BETWEEN 500 AND 1000 THEN 'Frequent'
            ELSE 'Occasional'
        END AS customer_tier
    FROM customer_data
    WHERE rn <= 5
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_item_sk) AS unique_returned_items
    FROM store_returns
    GROUP BY sr_customer_sk
),
final_report AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.customer_tier,
        COALESCE(cr.total_returns, 0) AS total_returns,
        cr.unique_returned_items,
        ARRAY_AGG(DISTINCT w.ws_order_number) AS order_numbers
    FROM ranked_customers rc
    LEFT JOIN customer_returns cr ON rc.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN web_sales w ON rc.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY rc.c_customer_sk, rc.c_first_name, rc.c_last_name, rc.cd_gender, rc.customer_tier
)
SELECT 
    f.*,
    CASE 
        WHEN f.total_returns = 0 THEN 'No Returns'
        WHEN f.unique_returned_items > 5 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS return_category,
    (SELECT COUNT(*) FROM store WHERE s_country = 'USA' AND s_state = 'CA') AS total_stores_in_CA,
    (SELECT AVG(ss_sales_price) FROM store_sales WHERE ss_item_sk IN (SELECT DISTINCT i_item_sk FROM item WHERE i_category = 'Electronics')) AS avg_electronics_price
FROM final_report f
WHERE f.customer_tier = 'VIP' OR f.customer_tier = 'Frequent'
ORDER BY f.total_spent DESC
LIMIT 10;
