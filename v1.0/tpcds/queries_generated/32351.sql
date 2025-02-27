
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_ext_sales_price) > 1000
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        COALESCE(SUM(ws_quantity), 0) AS total_sold,
        AVG(i.i_current_price) OVER (PARTITION BY i.i_brand) AS avg_brand_price,
        CASE 
            WHEN AVG(i.i_current_price) OVER (PARTITION BY i.i_brand) <= 50 THEN 'Budget'
            WHEN AVG(i.i_current_price) OVER (PARTITION BY i.i_brand) BETWEEN 51 AND 150 THEN 'Mid-range'
            ELSE 'Premium'
        END AS price_category
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_current_price, i.i_brand
)
SELECT 
    a.ca_city,
    SUM(s.total_sales) AS city_total_sales,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    AVG(d.avg_current_price) AS avg_item_price,
    MAX(d.price_category) AS max_price_category
FROM SalesCTE s
JOIN ItemDetails d ON s.ws_item_sk = d.i_item_sk
JOIN customer c ON c.c_customer_sk = d.i_item_sk
JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE a.ca_state = 'CA'
GROUP BY a.ca_city
HAVING city_total_sales > 5000
ORDER BY city_total_sales DESC
LIMIT 10;
