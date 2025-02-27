
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws_item_sk, d.d_date
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity,
    rs.total_sales,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_type,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion
FROM 
    ranked_sales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    promotion p ON i.i_item_sk = p.p_item_sk 
    AND CURRENT_DATE BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE 
    rs.total_sales > 1000
    AND EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_number_employees > 50 AND s.s_state = 'CA'
    )
ORDER BY 
    rs.total_sales DESC
LIMIT 10;
