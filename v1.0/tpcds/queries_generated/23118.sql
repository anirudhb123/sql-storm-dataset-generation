
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank_net_paid,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
PromotionSummary AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT p.p_item_sk) AS total_items_promoted,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discounts
    FROM 
        promotion p
    WHERE 
        EXISTS (
            SELECT 1
            FROM RankedSales rs
            WHERE rs.ws_item_sk = p.p_item_sk
        )
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(COALESCE(total_sales.ws_net_paid, 0)) AS total_sales_value,
    SUM(total_quantity) AS total_quantity_sold,
    MAX(COALESCE(ps.total_items_promoted, 0)) AS max_promotions,
    AVG(COALESCE(ps.active_discounts, 0.0)) AS avg_active_discounts
FROM 
    customer_address ca 
LEFT JOIN 
    (SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_paid,
        rs.total_quantity
     FROM 
        RankedSales rs 
     LEFT JOIN 
        store_sales ss ON rs.ws_item_sk = ss.ss_item_sk
    ) AS total_sales ON total_sales.ws_order_number IS NOT NULL
LEFT JOIN 
    PromotionSummary ps ON ps.p_promo_sk = 
        (SELECT p.p_promo_sk 
         FROM promotion p 
         WHERE p.p_item_sk = total_sales.ws_item_sk 
         ORDER BY p.p_start_date_sk DESC LIMIT 1)
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(total_sales.ws_net_paid) > (SELECT AVG(total_net_paid) FROM RankedSales)
ORDER BY 
    SUM(total_sales.ws_net_paid) DESC;
