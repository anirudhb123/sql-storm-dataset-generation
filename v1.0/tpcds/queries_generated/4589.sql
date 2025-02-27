
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
promotion_summary AS (
    SELECT 
        ws_item_sk,
        MAX(p.p_discount_active) AS is_discount_active
    FROM 
        web_sales ws
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        ws_item_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit,
        ps.is_discount_active,
        RANK() OVER (PARTITION BY ps.is_discount_active ORDER BY ss.total_profit DESC) AS profit_rank
    FROM 
        sales_summary ss
    JOIN 
        promotion_summary ps ON ss.ws_item_sk = ps.ws_item_sk
)
SELECT 
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    r.total_profit,
    r.is_discount_active
FROM 
    ranked_sales r
WHERE 
    r.profit_rank <= 10 
    AND r.is_discount_active = 'Y'
ORDER BY 
    r.total_profit DESC;

-- Perform a LEFT JOIN with a correlated subquery to bring in items 
-- that have no sales records for the year
SELECT 
    i.i_item_id,
    COALESCE(r.total_quantity, 0) AS total_quantity_sold,
    COALESCE(r.total_sales, 0) AS total_sales_amount
FROM 
    item i
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
) r ON i.i_item_sk = r.ws_item_sk
WHERE 
    i.i_rec_start_date <= CURRENT_DATE 
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE);
