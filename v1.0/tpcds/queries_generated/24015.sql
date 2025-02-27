
WITH RECURSIVE address_counts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count 
    FROM 
        customer_address 
    GROUP BY 
        ca_state
), 
promotions AS (
    SELECT 
        p.p_promo_id, 
        SUM(CASE 
            WHEN ws.ws_sales_price IS NULL THEN 0 
            ELSE (ws.ws_sales_price - ws.ws_ext_discount_amt) 
        END) AS total_sales 
    FROM 
        promotion p 
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
    GROUP BY 
        p.p_promo_id
),
sales_totals AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit 
    FROM 
        web_sales ws 
    WHERE
        ws.ws_shipped_date_sk IS NOT NULL 
        AND ws.ws_net_paid_inc_tax > 100
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ca.ca_state,
    COALESCE(ac.address_count, 0) AS total_addresses,
    COALESCE(pt.total_sales, 0) AS promotion_sales,
    COALESCE(st.total_quantity, 0) AS total_quantity,
    COALESCE(st.total_profit, 0) AS total_profit 
FROM 
    customer_address ca 
LEFT JOIN 
    address_counts ac ON ca.ca_state = ac.ca_state 
LEFT JOIN 
    promotions pt ON ca.ca_state IN (
        SELECT DISTINCT cd_gender 
        FROM customer_demographics 
        WHERE cd_purchase_estimate > 500 AND cd_marital_status = 'M'
    )
LEFT JOIN 
    sales_totals st ON ca.ca_address_sk = st.ws_item_sk
WHERE 
    ca.ca_city LIKE '%Ville%' 
    AND ca.ca_country = 'USA' 
    AND (ca.ca_gmt_offset IS NULL OR ca.ca_gmt_offset > -5.00)
ORDER BY 
    ca.ca_state, total_sales DESC
FETCH FIRST 100 ROWS ONLY;
