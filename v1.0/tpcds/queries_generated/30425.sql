
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY
        ws_item_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_current_price,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
SalesSummary AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        id.i_item_id,
        id.i_product_name,
        id.i_brand,
        id.i_current_price,
        id.inventory_on_hand
    FROM
        SalesCTE sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    s.i_item_id,
    s.i_product_name,
    s.i_brand,
    s.total_sales,
    s.order_count,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High Seller' 
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Seller' 
        ELSE 'Low Seller' 
    END AS Sales_Category,
    ROUND((s.total_sales / NULLIF(s.order_count, 0)), 2) AS avg_sales_per_order,
    s.inventory_on_hand,
    CASE 
        WHEN s.inventory_on_hand IS NULL THEN 'No Inventory' 
        WHEN s.inventory_on_hand = 0 THEN 'Out of Stock' 
        ELSE 'In Stock' 
    END AS Stock_Status
FROM 
    SalesSummary s 
WHERE 
    s.rank <= 10 
ORDER BY 
    s.total_sales DESC
