
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_sales, 0) AS total_sales
    FROM 
        item
    LEFT JOIN 
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE 
        item.i_rec_start_date <= CURRENT_DATE 
        AND (item.i_rec_end_date IS NULL OR item.i_rec_end_date > CURRENT_DATE)
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    CASE 
        WHEN ti.total_sales > 10000 THEN 'High'
        WHEN ti.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (SELECT COUNT(DISTINCT cc.cc_call_center_sk) 
     FROM call_center cc 
     WHERE cc.cc_open_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)) AS active_call_centers,
    (SELECT STRING_AGG(DISTINCT ca.ca_state, ', ') 
     FROM customer_address ca 
     JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk 
     WHERE c.c_birth_country = 'USA') AS usa_states
FROM 
    TopItems ti
WHERE 
    ti.total_quantity > 10
ORDER BY 
    ti.total_sales DESC
LIMIT 10;
