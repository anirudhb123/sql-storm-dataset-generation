
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_order_number,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
),
filtered_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_order_number,
        CASE 
            WHEN rs.rank_sales = 1 THEN 'Highest Price'
            ELSE 'Other Prices'
        END AS sales_category
    FROM 
        ranked_sales rs
    WHERE 
        rs.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales) 
        OR rs.ws_sales_price IS NULL
),
final_sales AS (
    SELECT 
        fs.ws_item_sk,
        SUM(fs.ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT fs.ws_order_number) AS order_count,
        MAX(fs.ws_sales_price) AS max_price
    FROM 
        filtered_sales fs
    GROUP BY 
        fs.ws_item_sk
)
SELECT 
    i.i_item_desc,
    fs.total_sales_price,
    COALESCE(fs.order_count, 0) AS order_count,
    fs.max_price,
    sm.sm_code AS shipping_method,
    COALESCE(c.c_first_name, 'Unknown') AS first_name,
    COALESCE(c.c_last_name, 'Unknown') AS last_name,
    CASE 
        WHEN fs.total_sales_price IS NULL THEN 'No Sales Data'
        WHEN fs.total_sales_price > 1000 THEN 'High Roller'
        ELSE 'Regular Buyer'
    END AS customer_status,
    SWAP(fruit, veg) AS swap_data -- Assume a function that swaps the data if needed
FROM 
    final_sales fs
JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    web_returns wr ON fs.ws_item_sk = wr.wr_item_sk AND wr.wr_order_number = fs.ws_order_number
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT ws_ship_mode_sk FROM web_sales WHERE ws_item_sk = fs.ws_item_sk LIMIT 1)
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_item_sk = fs.ws_item_sk LIMIT 1)
WHERE 
    fs.total_sales_price > COALESCE((SELECT MAX(total_sales_price) FROM final_sales), 0) * 0.5
    OR i.i_item_desc LIKE '%Special%'
ORDER BY 
    fs.total_sales_price DESC
FETCH FIRST 10 ROWS ONLY;
