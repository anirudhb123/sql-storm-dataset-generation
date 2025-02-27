
WITH RECURSIVE SalesAnalysis AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_order_number
),
TopSales AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        sales.total_quantity,
        sales.total_sales,
        ROW_NUMBER() OVER (ORDER BY sales.total_sales DESC) AS sales_rank
    FROM SalesAnalysis sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.total_quantity > 0
)
SELECT 
    t.i_item_id,
    t.i_product_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.total_quantity, 0) AS total_quantity,
    (SELECT COUNT(DISTINCT cc.cc_call_center_sk) FROM call_center cc) AS call_centers_count,
    (SELECT COUNT(DISTINCT ca.ca_address_sk) FROM customer_address ca) AS unique_addresses,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No Sales'
        WHEN t.total_sales > 10000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM TopSales t
FULL OUTER JOIN store st ON t.total_quantity > 0 AND st.s_store_sk IS NOT NULL
WHERE t.sales_rank <= 10
ORDER BY t.total_sales DESC;
