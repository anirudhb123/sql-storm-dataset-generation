
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_ext_tax) AS total_tax,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND 
                d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_dow IN (1, 2))
        )
    GROUP BY 
        ss_store_sk
),
customer_info AS (
    SELECT 
        c_customer_sk,
        MAX(CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END) AS gender,
        MAX(cd_marital_status) AS marital_status,
        COALESCE(MAX(cd_purchase_estimate), 0) AS purchase_estimate,
        COALESCE(MAX(cd_credit_rating), 'Not Rated') AS credit_rating
    FROM 
        customer 
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_customer_sk
),
promotions_summary AS (
    SELECT 
        p_item_sk,
        COUNT(DISTINCT p_promo_sk) AS total_promotions
    FROM 
        promotion
    WHERE 
        p_discount_active = 'Y'
    GROUP BY 
        p_item_sk
),
inventory_status AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
)
SELECT 
    s_store_sk AS store_id,
    cs.total_quantity,
    cs.total_net_paid,
    cs.total_tax,
    ci.gender,
    ci.marital_status,
    ci.purchase_estimate,
    ci.credit_rating,
    COALESCE(ps.total_promotions, 0) AS active_promotions,
    COALESCE(is.total_quantity_on_hand, 0) AS available_inventory,
    CASE 
        WHEN cs.total_net_paid IS NULL THEN 'No Sales'
        WHEN cs.total_net_paid < 1000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    sales_summary cs 
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk = 
        (SELECT MIN(c_customer_sk) FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'Los Angeles'))
LEFT JOIN 
    promotions_summary ps ON ps.p_item_sk = 
        (SELECT MIN(i_item_sk) FROM item WHERE i_brand_id IN (SELECT i_brand_id FROM item WHERE i_category LIKE '%Electronics%'))
LEFT JOIN 
    inventory_status is ON is.inv_item_sk = 
        (SELECT MAX(i_item_sk) FROM item)
WHERE 
    cs.total_quantity > 0 
    AND (ci.purchase_estimate > 1000 OR ci.credit_rating IS NULL)
ORDER BY 
    cs.total_net_paid DESC
LIMIT 100;
