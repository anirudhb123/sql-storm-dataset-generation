
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ranked_sales AS (
    SELECT
        sd.ws_item_sk,
        d.d_month_seq,
        d.d_year,
        sd.total_sales,
        sd.total_revenue,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_revenue DESC) AS revenue_rank
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        r.d_month_seq,
        r.d_year,
        r.total_sales,
        r.total_revenue,
        COALESCE(sm.sm_type, 'Unknown') AS shipping_method
    FROM 
        ranked_sales r
    LEFT JOIN 
        ship_mode sm ON sm.sm_ship_mode_sk = (
            SELECT 
                ws_ship_mode_sk 
            FROM 
                web_sales 
            WHERE 
                ws_item_sk = r.ws_item_sk 
            LIMIT 1
        )
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    s.total_sales,
    s.total_revenue,
    s.shipping_method
FROM 
    top_sales s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE 
            ss.ss_item_sk = s.ws_item_sk 
            AND ss.ss_sold_date_sk IN (
                SELECT d_date_sk 
                FROM date_dim 
                WHERE d_month_seq = s.d_month_seq AND d_year = s.d_year
            )
    )
ORDER BY 
    s.total_revenue DESC, i.i_product_name
LIMIT 50;
