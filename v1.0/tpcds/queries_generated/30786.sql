
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk, ws_ship_mode_sk
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        coalesce(s.total_sales, 0) AS total_sales,
        coalesce(s.total_quantity, 0) AS total_quantity,
        d.d_dow AS week_day,
        (CASE 
             WHEN d.d_holiday = 'Y' THEN 'Holiday'
             ELSE 'Regular Day'
         END) AS sale_type
    FROM 
        item
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_net_paid) AS total_sales,
            SUM(ws_quantity) AS total_quantity,
            ws_ship_mode_sk
        FROM 
            sales_cte 
        WHERE 
            rn = 1
        GROUP BY 
            ws_item_sk, ws_ship_mode_sk
    ) AS s ON item.i_item_sk = s.ws_item_sk
    JOIN date_dim d ON d.d_date_sk = (SELECT 
                                            date_dim.d_date_sk 
                                        FROM 
                                            date_dim 
                                        WHERE 
                                            d_date = '2023-01-01' AND 
                                            DOW = 1
                                    )
),
ranked_sales AS (
    SELECT 
        i_item_id,
        i_product_name,
        total_sales,
        total_quantity,
        sale_type,
        RANK() OVER (PARTITION BY sale_type ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    r.i_item_id,
    r.i_product_name,
    r.total_sales,
    r.total_quantity,
    r.sale_type
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    sale_type, total_sales DESC;
