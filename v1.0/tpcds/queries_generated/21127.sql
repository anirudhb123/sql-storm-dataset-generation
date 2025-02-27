
WITH recursive sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
inventory_status AS (
    SELECT 
        inv_item_sk,
        AVG(inv_quantity_on_hand) AS avg_quantity,
        MAX(inv_quantity_on_hand) AS max_quantity,
        MIN(inv_quantity_on_hand) AS min_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
return_stats AS (
    SELECT 
        cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
final_selection AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        is.avg_quantity,
        is.max_quantity,
        is.min_quantity,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
        CASE 
            WHEN COALESCE(rs.total_return_amount, 0) > 0 AND sd.total_sales > 0 THEN 
                (COALESCE(rs.total_return_amount, 0) / sd.total_sales) * 100 
            ELSE 
                NULL 
        END AS return_percentage
    FROM 
        sales_data sd
    LEFT JOIN 
        inventory_status is ON sd.ws_item_sk = is.inv_item_sk
    LEFT JOIN 
        return_stats rs ON sd.ws_item_sk = rs.cr_item_sk
    WHERE 
        sd.sales_rank <= 10 
        AND (is.avg_quantity - is.min_quantity) > 5 
        AND (is.max_quantity IS NOT NULL OR rs.total_returns > 0)
)
SELECT 
    fs.ws_item_sk,
    fs.total_sales,
    fs.order_count,
    fs.avg_quantity,
    fs.max_quantity,
    fs.min_quantity,
    fs.total_returns,
    fs.total_return_amount,
    fs.total_return_quantity,
    ROW_NUMBER() OVER (ORDER BY fs.total_sales DESC) AS row_num
FROM 
    final_selection fs
WHERE 
    (fs.return_percentage > 50 OR fs.total_sales > 1000)
ORDER BY 
    fs.total_sales DESC
LIMIT 50;

