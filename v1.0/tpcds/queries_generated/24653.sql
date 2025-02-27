
WITH demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate BETWEEN 1 AND 100 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 101 AND 500 THEN 'Medium'
            WHEN cd_purchase_estimate > 500 THEN 'High'
            ELSE 'Undefined'
        END AS purchase_level,
        CD.credit_rating
    FROM customer_demographics cd
    WHERE cd_gender IS NOT NULL
),
address AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM customer_address
),
totals AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY i_current_price DESC) AS price_rank
    FROM item
    WHERE i_current_price IS NOT NULL
)
SELECT
    c.c_customer_id,
    d.cd_demo_sk,
    ad.full_address,
    d.purchase_level,
    tt.total_spent,
    tt.order_count,
    SUM(CASE WHEN i.price_rank <= 5 THEN i.i_current_price ELSE 0 END) AS top_items_spent,
    COUNT(DISTINCT CASE 
        WHEN r.r_reason_desc IS NOT NULL THEN r.r_reason_desc 
        ELSE 'No Reason' 
    END) AS distinct_return_reasons
FROM customer c
LEFT JOIN demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN address ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN totals tt ON c.c_customer_sk = tt.customer_sk
LEFT JOIN (
    SELECT wr_returned_date_sk, wr_order_number, wr_item_sk, r.r_reason_desc
    FROM web_returns wr
    LEFT JOIN reason r ON wr_wr_reason_sk = r.r_reason_sk
) r ON r.wr_order_number IN (
    SELECT cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk = c.c_customer_sk
)
LEFT JOIN items i ON i.i_item_sk IN (
    SELECT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_customer_sk = c.c_customer_sk
)
WHERE c.c_birth_year IS NOT NULL
AND (ad.ca_state = 'NY' OR ad.ca_state = 'CA')
GROUP BY 
    c.c_customer_id,
    d.cd_demo_sk,
    ad.full_address,
    d.purchase_level,
    tt.total_spent,
    tt.order_count
HAVING 
    COALESCE(SUM(i.i_current_price), 0) > 100 
    OR COUNT(DISTINCT r.r_reason_desc) > 1
ORDER BY d.cd_purchase_estimate DESC, ad.ca_city;
