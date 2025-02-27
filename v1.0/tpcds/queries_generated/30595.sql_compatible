
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        RecursiveSales
),
DiscountedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price * 0.9 AS discounted_price,
        cs_quantity,
        cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number DESC) AS order_rank
    FROM 
        catalog_sales
    WHERE 
        cs_order_number IN (
            SELECT ws_order_number 
            FROM web_sales 
            WHERE ws_item_sk IN (SELECT ws_item_sk FROM TopItems WHERE rank <= 10)
        )
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    t.total_quantity,
    t.total_sales,
    ds.discounted_price,
    AVG(ds.discounted_price) OVER (PARTITION BY ds.cs_item_sk) AS avg_discounted_price,
    COUNT(ds.cs_item_sk) AS sales_count
FROM 
    TopItems t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
LEFT JOIN 
    DiscountedSales ds ON t.ws_item_sk = ds.cs_item_sk
WHERE 
    t.total_quantity > 100
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    t.total_quantity,
    t.total_sales,
    ds.discounted_price
ORDER BY 
    t.total_sales DESC, 
    sales_count DESC;
