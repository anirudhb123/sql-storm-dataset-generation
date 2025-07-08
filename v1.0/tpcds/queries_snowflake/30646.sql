
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 20000
),
AggregatedSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(sales.ws_quantity) AS total_quantity,
        SUM(sales.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sales.ws_order_number) AS order_count
    FROM 
        SalesCTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id,
        item.i_product_name
)
SELECT 
    a.i_item_id,
    a.i_product_name,
    a.total_quantity,
    a.total_sales,
    (SELECT 
         AVG(total_sales) 
     FROM 
         AggregatedSales 
     WHERE 
         total_quantity > (SELECT AVG(total_quantity) FROM AggregatedSales)) AS avg_above_average_sales,
    (SELECT 
         COUNT(*) 
     FROM 
         customer c 
     WHERE 
         c.c_birth_year = (SELECT MAX(c_birth_year) FROM customer)
     AND 
         c.c_current_addr_sk IS NOT NULL) AS latest_customers,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name
FROM 
    AggregatedSales a
LEFT JOIN 
    promotion p ON p.p_item_sk = (SELECT 
                                       i_item_sk 
                                   FROM 
                                       item 
                                   WHERE 
                                       i_item_id = a.i_item_id 
                                   LIMIT 1)
WHERE 
    a.total_sales > (SELECT AVG(total_sales) FROM AggregatedSales)
ORDER BY 
    a.total_sales DESC
LIMIT 10;
