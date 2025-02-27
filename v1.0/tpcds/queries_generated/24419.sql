
WITH Ranked_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
Filtered_Items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Unknown Price'
            WHEN i.i_current_price < 0 THEN 'Negative Price'
            ELSE 'Valid Price'
        END AS price_status
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
Top_Sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        f.i_item_id,
        f.i_product_name,
        f.price_status
    FROM 
        Ranked_Sales r
    JOIN 
        Filtered_Items f ON r.ws_item_sk = f.i_item_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    ROUND(t.total_net_paid, 2) AS total_net_paid,
    t.i_item_id,
    t.i_product_name,
    t.price_status,
    COALESCE(MAX(rp.p_discount_active), 'N') AS discount_active_status,
    AVG(CASE WHEN r.ws_item_sk IS NULL THEN NULL ELSE rws.ws_net_profit END) AS avg_profit,
    MIN(s.s_store_name) AS store_name
FROM 
    Top_Sales t
LEFT JOIN 
    promotion rp ON t.ws_item_sk = rp.p_item_sk
LEFT JOIN 
    store_sales s ON t.ws_item_sk = s.ss_item_sk
LEFT JOIN 
    web_sales rws ON t.ws_item_sk = rws.ws_item_sk 
GROUP BY 
    t.ws_item_sk, t.total_quantity, t.total_net_paid, t.i_item_id, 
    t.i_product_name, t.price_status
HAVING 
    COUNT(DISTINCT rp.p_promo_sk) > 0 
    OR AVG(t.total_net_paid) > (SELECT AVG(total_net_paid) FROM Top_Sales)
ORDER BY 
    t.total_net_paid DESC NULLS LAST
FETCH FIRST 20 ROWS ONLY;
