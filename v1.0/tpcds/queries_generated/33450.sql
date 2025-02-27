
WITH RECURSIVE profit_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
        COALESCE(d.d_year, 0) AS sale_year,
        COALESCE(s.s_store_name, 'Unknown Store') AS store_name
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
    LEFT JOIN 
        store_sales s ON i.i_item_sk = s.ss_item_sk
    LEFT JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
)
SELECT 
    d.i_item_sk,
    d.i_item_desc,
    d.promotion_name,
    ps.total_profit,
    d.sale_year,
    d.store_name
FROM 
    item_details d
JOIN 
    profit_summary ps ON d.i_item_sk = ps.ws_item_sk
WHERE 
    ps.total_profit IS NOT NULL 
    AND ps.rnk <= 10
ORDER BY 
    ps.total_profit DESC;

SELECT 
    DISTINCT city, state 
FROM 
    customer_address 
WHERE 
    ca_city IS NOT NULL 
    AND (ca_state IS NULL OR ca_state <> 'NY')
ORDER BY 
    city;
