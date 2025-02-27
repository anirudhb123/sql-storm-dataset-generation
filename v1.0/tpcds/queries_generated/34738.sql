
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_item_sk
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        sd.ws_sold_date_sk + 1,
        sd.total_sales * 0.95, -- Simulating a 5% decrease in sales each subsequent day
        sd.total_orders,
        sd.ws_item_sk
    FROM SalesData sd
    WHERE sd.ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS rnk
    FROM SalesData sd
),
ItemDetail AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM item i
    LEFT JOIN FilteredSales sd ON i.i_item_sk = sd.ws_item_sk
    WHERE sd.rnk = 1
)
SELECT 
    id.i_product_name,
    id.i_brand,
    id.total_sales,
    CASE 
        WHEN id.total_sales > 5000 THEN 'High Sales'
        WHEN id.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    COUNT(c.c_customer_sk) AS customer_count,
    SUM(COALESCE(cs.cs_quantity, 0)) AS total_quantity_sold
FROM ItemDetail id
LEFT JOIN store_sales cs ON id.i_item_sk = cs.ss_item_sk
LEFT JOIN customer c ON cs.ss_customer_sk = c.c_customer_sk
WHERE id.total_sales IS NOT NULL
GROUP BY id.i_product_name, id.i_brand, id.total_sales
ORDER BY total_sales DESC
FETCH FIRST 10 ROWS ONLY;
